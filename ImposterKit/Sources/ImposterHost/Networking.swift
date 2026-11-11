import Foundation
import Network

/// Runs a closure at most once. Used to settle a continuation from several callbacks.
final class OnceFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var fired = false

    /// Returns true the first time only.
    func fire() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if fired { return false }
        fired = true
        return true
    }
}

/// Starts a TCP listener and waits until it is ready, or throws why it could not be.
func startListener(
    parameters: NWParameters,
    port: UInt16,
    queue: DispatchQueue,
    onConnection: @escaping @Sendable (NWConnection) -> Void,
    onFailure: @escaping @Sendable (NWError) -> Void
) async throws -> NWListener {
    guard let nwPort = NWEndpoint.Port(rawValue: port) else { throw NWError.posix(.EINVAL) }
    let listener = try NWListener(using: parameters, on: nwPort)
    listener.newConnectionHandler = onConnection

    let once = OnceFlag()
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                if once.fire() { continuation.resume() }
            case .failed(let error):
                if once.fire() {
                    listener.cancel()
                    continuation.resume(throwing: error)
                } else {
                    onFailure(error)
                }
            case .waiting(let error):
                // Usually "address in use" or a denied permission. Give it a moment, then give up.
                queue.asyncAfter(deadline: .now() + 1.5) {
                    if once.fire() {
                        listener.cancel()
                        continuation.resume(throwing: error)
                    }
                }
            default:
                break
            }
        }
        listener.start(queue: queue)
    }
    return listener
}

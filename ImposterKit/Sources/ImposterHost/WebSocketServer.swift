import Foundation
import Network

/// What a connected phone did, in order.
enum PeerEvent: Sendable {
    case text(String)
    case closed
}

/// One accepted WebSocket connection. Events arrive in order on `events`; the stream ends after `.closed`.
final class WebSocketPeer: @unchecked Sendable {
    let id = UUID()
    let events: AsyncStream<PeerEvent>
    private let connection: NWConnection
    private let continuation: AsyncStream<PeerEvent>.Continuation
    private let closed = OnceFlag()

    init(connection: NWConnection, queue: DispatchQueue) {
        self.connection = connection
        (events, continuation) = AsyncStream.makeStream(of: PeerEvent.self)
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .failed, .cancelled:
                self?.finish()
            case .waiting:
                connection.cancel()
            default:
                break
            }
        }
        connection.start(queue: queue)
        receive()
    }

    private func finish() {
        guard closed.fire() else { return }
        continuation.yield(.closed)
        continuation.finish()
    }

    private func receive() {
        connection.receiveMessage { [weak self] data, context, _, error in
            guard let self else { return }
            if error != nil {
                connection.cancel()
                return
            }
            let metadata = context?.protocolMetadata(definition: NWProtocolWebSocket.definition) as? NWProtocolWebSocket.Metadata
            switch metadata?.opcode {
            case .close:
                connection.cancel()
                return
            case .text:
                if let data, let text = String(data: data, encoding: .utf8) {
                    continuation.yield(.text(text))
                }
            default:
                break
            }
            receive()
        }
    }

    func send(_ text: String, thenClose: Bool = false) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "text", metadata: [metadata])
        connection.send(content: Data(text.utf8), contentContext: context, isComplete: true, completion: .contentProcessed { [connection] _ in
            if thenClose { connection.cancel() }
        })
    }

    func close() {
        connection.cancel()
    }
}

/// Accepts WebSocket connections on a port.
final class WebSocketServer: Sendable {
    private let listener: NWListener

    private init(listener: NWListener) {
        self.listener = listener
    }

    static func start(
        port: UInt16,
        onPeer: @escaping @Sendable (WebSocketPeer) -> Void,
        onFailure: @escaping @Sendable (NWError) -> Void
    ) async throws -> WebSocketServer {
        let options = NWProtocolWebSocket.Options()
        options.autoReplyPing = true
        options.maximumMessageSize = 64 * 1024
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)
        let queue = DispatchQueue(label: "imposter.ws")
        let listener = try await startListener(
            parameters: parameters,
            port: port,
            queue: queue,
            onConnection: { connection in onPeer(WebSocketPeer(connection: connection, queue: queue)) },
            onFailure: onFailure
        )
        return WebSocketServer(listener: listener)
    }

    func stop() {
        listener.cancel()
    }
}

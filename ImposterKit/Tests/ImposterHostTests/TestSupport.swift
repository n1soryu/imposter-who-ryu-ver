import Foundation
import ImposterHost
import ImposterKit

/// Picks a fresh high port pair for each test so servers never collide.
@MainActor
enum TestPorts {
    private static var next = UInt16.random(in: 30000...50000) & ~1

    static func pair() -> PortPair {
        defer { next += 2 }
        return PortPair(http: next, ws: next + 1)
    }
}

struct TimedOut: Error, CustomStringConvertible {
    let description: String
}

@MainActor
func makeController(remote: Bool = false) async throws -> HostController {
    let controller = try HostController(
        hostName: "Host",
        library: try WordLibrary.bundled(),
        allowsRemoteHostCommands: remote,
        ports: (0..<6).map { _ in TestPorts.pair() }
    )
    await controller.startListening()
    guard controller.status == .running else { throw TimedOut(description: "listener failed: \(String(describing: controller.errorMessage))") }
    return controller
}

/// Polls until the condition holds.
@MainActor
func eventually(_ what: String, timeout: Duration = .seconds(5), _ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now + timeout
    while condition() == false {
        guard ContinuousClock.now < deadline else { throw TimedOut(description: what) }
        try await Task.sleep(for: .milliseconds(20))
    }
}

/// A phone, as a WebSocket client.
@MainActor
final class TestClient {
    typealias JSON = [String: Any]

    private let task: URLSessionWebSocketTask
    private(set) var playerID: String?
    private(set) var token: String?

    init(port: UInt16) {
        task = URLSession.shared.webSocketTask(with: URL(string: "ws://127.0.0.1:\(port)")!)
        task.resume()
    }

    func send(_ object: JSON) async throws {
        let data = try JSONSerialization.data(withJSONObject: object)
        try await task.send(.string(String(decoding: data, as: UTF8.self)))
    }

    func close() {
        task.cancel(with: .goingAway, reason: nil)
    }

    private func receiveText(timeout: Duration) async throws -> String {
        let watchdog = Task { [task] in
            try await Task.sleep(for: timeout)
            task.cancel(with: .goingAway, reason: nil)
        }
        defer { watchdog.cancel() }
        switch try await task.receive() {
        case .string(let text): return text
        case .data(let data): return String(decoding: data, as: UTF8.self)
        @unknown default: throw TimedOut(description: "unknown message")
        }
    }

    /// Reads messages until one matches. Remembers the welcome.
    @discardableResult
    func wait(_ what: String, timeout: Duration = .seconds(5), where matches: (JSON) -> Bool) async throws -> JSON {
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            let text = try await receiveText(timeout: timeout)
            guard let json = try JSONSerialization.jsonObject(with: Data(text.utf8)) as? JSON else { continue }
            if json["type"] as? String == "welcome" {
                playerID = json["playerId"] as? String
                token = json["token"] as? String
            }
            if matches(json) { return json }
        }
        throw TimedOut(description: what)
    }

    @discardableResult
    func wait(type: String, timeout: Duration = .seconds(5)) async throws -> JSON {
        try await wait("message of type \(type)", timeout: timeout) { $0["type"] as? String == type }
    }

    /// Waits for a state whose phase has this name.
    @discardableResult
    func waitForPhase(_ name: String) async throws -> JSON {
        try await wait("phase \(name)") { json in
            guard json["type"] as? String == "state", let view = json["view"] as? JSON, let phase = view["phase"] as? JSON else { return false }
            return phase["name"] as? String == name
        }
    }

    @discardableResult
    func join(_ name: String) async throws -> JSON {
        try await send(["type": "join", "name": name])
        return try await wait(type: "welcome")
    }
}

func get(_ url: String, method: String = "GET") async throws -> (status: Int, headers: [String: String], body: String) {
    var request = URLRequest(url: URL(string: url)!)
    request.httpMethod = method
    request.timeoutInterval = 5
    let (data, response) = try await URLSession.shared.data(for: request)
    let http = response as! HTTPURLResponse
    var headers: [String: String] = [:]
    for (key, value) in http.allHeaderFields { headers["\(key)".lowercased()] = "\(value)" }
    return (http.statusCode, headers, String(decoding: data, as: UTF8.self))
}

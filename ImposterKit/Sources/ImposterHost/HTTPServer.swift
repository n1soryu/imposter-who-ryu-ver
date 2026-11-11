import Foundation
import Network

/// A tiny HTTP/1.1 file server for the bundled browser client. `GET` and `HEAD` only.
final class HTTPServer: Sendable {
    private let listener: NWListener

    private init(listener: NWListener) {
        self.listener = listener
    }

    static func start(
        port: UInt16,
        wsPort: UInt16,
        root: URL,
        onFailure: @escaping @Sendable (NWError) -> Void
    ) async throws -> HTTPServer {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        let queue = DispatchQueue(label: "imposter.http")
        let handler = HTTPHandler(root: root, wsPort: wsPort)
        let listener = try await startListener(
            parameters: parameters,
            port: port,
            queue: queue,
            onConnection: { connection in handler.serve(connection, on: queue) },
            onFailure: onFailure
        )
        return HTTPServer(listener: listener)
    }

    func stop() {
        listener.cancel()
    }
}

struct HTTPRequest: Equatable {
    var method: String
    var target: String
}

struct HTTPHandler: Sendable {
    let root: URL
    let wsPort: UInt16

    private static let maximumRequestBytes = 16 * 1024

    func serve(_ connection: NWConnection, on queue: DispatchQueue) {
        connection.start(queue: queue)
        let buffer = RequestBuffer()
        receive(connection, buffer: buffer)
    }

    private final class RequestBuffer: @unchecked Sendable {
        var data = Data()
    }

    private func receive(_ connection: NWConnection, buffer: RequestBuffer) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data, _, isComplete, error in
            if let data { buffer.data.append(data) }
            if let end = buffer.data.range(of: Data("\r\n\r\n".utf8)) {
                let head = String(decoding: buffer.data[..<end.lowerBound], as: UTF8.self)
                let response = Self.respond(toHead: head, root: root, wsPort: wsPort)
                connection.send(content: response, contentContext: .finalMessage, isComplete: true, completion: .contentProcessed { _ in
                    connection.cancel()
                })
            } else if error != nil || isComplete || buffer.data.count > Self.maximumRequestBytes {
                connection.cancel()
            } else {
                receive(connection, buffer: buffer)
            }
        }
    }

    // MARK: Pure parts

    static func parse(head: String) -> HTTPRequest? {
        guard let line = head.split(separator: "\r\n", maxSplits: 1, omittingEmptySubsequences: false).first else { return nil }
        let parts = line.split(separator: " ")
        guard parts.count == 3, parts[2].hasPrefix("HTTP/") else { return nil }
        return HTTPRequest(method: String(parts[0]), target: String(parts[1]))
    }

    /// The file inside `root` a request path maps to, or `nil` for anything unsafe.
    static func resolve(target: String, root: URL) -> URL? {
        var path = target
        if let cut = path.firstIndex(where: { $0 == "?" || $0 == "#" }) { path = String(path[..<cut]) }
        guard path.hasPrefix("/"), let decoded = path.removingPercentEncoding, decoded.contains("\0") == false, decoded.contains("\\") == false else { return nil }
        let parts = decoded.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        if parts.contains(where: { $0.hasPrefix(".") }) { return nil }
        let relative = parts.isEmpty ? "index.html" : parts.joined(separator: "/")
        let file = root.appendingPathComponent(relative).standardizedFileURL
        guard file.path.hasPrefix(root.standardizedFileURL.path + "/") else { return nil }
        return file
    }

    static func contentType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "html", "htm": "text/html; charset=utf-8"
        case "css": "text/css; charset=utf-8"
        case "js", "mjs": "text/javascript; charset=utf-8"
        case "json": "application/json; charset=utf-8"
        case "ttf": "font/ttf"
        case "woff2": "font/woff2"
        case "woff": "font/woff"
        case "svg": "image/svg+xml"
        case "png": "image/png"
        case "ico": "image/x-icon"
        default: "application/octet-stream"
        }
    }

    static func respond(toHead head: String, root: URL, wsPort: UInt16) -> Data {
        guard let request = parse(head: head) else {
            return response(status: "400 Bad Request", type: "text/plain; charset=utf-8", body: Data("Bad request".utf8), includeBody: true)
        }
        guard request.method == "GET" || request.method == "HEAD" else {
            return response(status: "405 Method Not Allowed", type: "text/plain; charset=utf-8", body: Data("Method not allowed".utf8), includeBody: true, extra: ["Allow: GET, HEAD"])
        }
        let includeBody = request.method == "GET"
        let route = request.target.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? request.target

        if route == "/config.js" {
            let body = Data("window.IMPOSTER = { wsPort: \(wsPort) };\n".utf8)
            return response(status: "200 OK", type: "text/javascript; charset=utf-8", body: body, includeBody: includeBody)
        }
        if let file = resolve(target: request.target, root: root),
           (try? file.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true,
           let body = try? Data(contentsOf: file) {
            return response(status: "200 OK", type: contentType(for: file), body: body, includeBody: includeBody)
        }
        return response(status: "404 Not Found", type: "text/plain; charset=utf-8", body: Data("Not found".utf8), includeBody: includeBody)
    }

    private static func response(status: String, type: String, body: Data, includeBody: Bool, extra: [String] = []) -> Data {
        var lines = [
            "HTTP/1.1 \(status)",
            "Content-Type: \(type)",
            "Content-Length: \(body.count)",
            "Cache-Control: no-store",
            "Connection: close",
        ] + extra
        lines.append("")
        lines.append("")
        var data = Data(lines.joined(separator: "\r\n").utf8)
        if includeBody { data.append(body) }
        return data
    }
}

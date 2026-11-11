import Foundation
@testable import ImposterHost
import Testing

@MainActor
@Suite(.serialized)
struct HostHTTPTests {
    @Test func rootServesTheIndexPage() async throws {
        let controller = try await makeController()
        defer { controller.stopListening() }
        let response = try await get("http://127.0.0.1:\(controller.httpPort!)/")
        #expect(response.status == 200)
        #expect(response.headers["content-type"]?.hasPrefix("text/html") == true)
        #expect(response.headers["cache-control"] == "no-store")
        #expect(response.body.contains("/config.js"))
    }

    @Test func configCarriesTheWebSocketPort() async throws {
        let controller = try await makeController()
        defer { controller.stopListening() }
        let response = try await get("http://127.0.0.1:\(controller.httpPort!)/config.js")
        #expect(response.status == 200)
        #expect(response.headers["content-type"]?.hasPrefix("text/javascript") == true)
        #expect(response.body.contains("wsPort: \(controller.wsPort!)"))
    }

    @Test func fontsAreServed() async throws {
        let controller = try await makeController()
        defer { controller.stopListening() }
        let response = try await get("http://127.0.0.1:\(controller.httpPort!)/fonts/BricolageGrotesque-SemiBold.ttf", method: "HEAD")
        #expect(response.status == 200)
        #expect(response.headers["content-type"] == "font/ttf")
        #expect(response.body.isEmpty)
    }

    @Test func traversalAndUnknownPathsAreNotFound() async throws {
        let controller = try await makeController()
        defer { controller.stopListening() }
        let base = "http://127.0.0.1:\(controller.httpPort!)"
        for path in ["/../Package.swift", "/%2e%2e/Package.swift", "/fonts/../../Package.swift", "/nope.html", "/fonts"] {
            // URLSession normalises some of these, so send the raw request over a socket as well.
            let response = try await get(base + path)
            #expect(response.status == 404, "\(path)")
        }
    }

    @Test func rawTraversalIsNotFound() {
        let root = URL(fileURLWithPath: "/tmp/web")
        #expect(HTTPHandler.resolve(target: "/../Package.swift", root: root) == nil)
        #expect(HTTPHandler.resolve(target: "/%2e%2e/Package.swift", root: root) == nil)
        #expect(HTTPHandler.resolve(target: "/a/../../x", root: root) == nil)
        #expect(HTTPHandler.resolve(target: "/.hidden", root: root) == nil)
        #expect(HTTPHandler.resolve(target: "/fonts/a.ttf?x=1", root: root)?.path == "/tmp/web/fonts/a.ttf")
        let response = String(decoding: HTTPHandler.respond(toHead: "GET /../Package.swift HTTP/1.1\r\nHost: x", root: root, wsPort: 1), as: UTF8.self)
        #expect(response.hasPrefix("HTTP/1.1 404"))
    }

    @Test func otherMethodsAreRejected() {
        let root = URL(fileURLWithPath: "/tmp/web")
        let response = String(decoding: HTTPHandler.respond(toHead: "POST / HTTP/1.1\r\nHost: x", root: root, wsPort: 1), as: UTF8.self)
        #expect(response.hasPrefix("HTTP/1.1 405"))
        #expect(response.contains("Connection: close"))
    }

    @Test func addressPrefersHotspotThenWifi() {
        typealias I = LocalAddress.Interface
        #expect(LocalAddress.choose(from: [I(name: "en0", address: "192.168.1.5"), I(name: "bridge100", address: "172.20.10.1")]) == "172.20.10.1")
        #expect(LocalAddress.choose(from: [I(name: "utun3", address: "10.0.0.2"), I(name: "en0", address: "192.168.1.5")]) == "192.168.1.5")
        #expect(LocalAddress.choose(from: [I(name: "utun3", address: "10.0.0.2")]) == "10.0.0.2")
        #expect(LocalAddress.choose(from: [I(name: "lo0", address: "127.0.0.1")]) == nil)
    }
}

import Foundation
import ImposterHost
import ImposterKit
import Testing

@MainActor
@Suite(.serialized)
struct HostWebSocketTests {
    @Test func joinGetsWelcomeAndState() async throws {
        let controller = try await makeController()
        defer { controller.stopListening() }
        let ana = TestClient(port: controller.wsPort!)
        defer { ana.close() }

        // Before joining a phone sees the join screen.
        try await ana.waitForPhase("join")
        try await ana.send(["type": "join", "name": "Ana"])
        let welcome = try await ana.wait(type: "welcome")
        #expect(welcome["token"] as? String != nil)
        let lobby = try await ana.waitForPhase("lobby")
        let view = lobby["view"] as? [String: Any]
        #expect((view?["you"] as? [String: Any])?["name"] as? String == "Ana")
        #expect(controller.session.players.map(\.name) == ["Host", "Ana"])
    }

    @Test func secondClientSeesTheFirst() async throws {
        let controller = try await makeController()
        defer { controller.stopListening() }
        let ana = TestClient(port: controller.wsPort!)
        let ben = TestClient(port: controller.wsPort!)
        defer { ana.close(); ben.close() }
        try await ana.join("Ana")
        try await ben.join("Ben")
        // Ana is told about Ben.
        try await ana.wait("three players") { json in
            ((json["view"] as? [String: Any])?["players"] as? [Any])?.count == 3
        }
        #expect(controller.session.seats.count == 3)
        // A duplicate name is refused.
        let eve = TestClient(port: controller.wsPort!)
        defer { eve.close() }
        try await eve.send(["type": "join", "name": "ben"])
        let error = try await eve.wait(type: "error")
        #expect(error["code"] as? String == "nameTaken")
    }

    @Test func droppedPhoneResumesItsSeat() async throws {
        let controller = try await makeController()
        defer { controller.stopListening() }
        let first = TestClient(port: controller.wsPort!)
        try await first.join("Ana")
        let seatID = first.playerID
        let token = try #require(first.token)
        first.close()
        try await eventually("disconnect noticed") { controller.session.seats.last?.isConnected == false }

        let second = TestClient(port: controller.wsPort!)
        defer { second.close() }
        try await second.send(["type": "resume", "token": token])
        let welcome = try await second.wait(type: "welcome")
        #expect(welcome["playerId"] as? String == seatID)
        let state = try await second.waitForPhase("lobby")
        #expect(((state["view"] as? [String: Any])?["you"] as? [String: Any])?["id"] as? String == seatID)
        try await eventually("reconnected") { controller.session.seats.last?.isConnected == true }
    }

    @Test func newerConnectionReplacesTheOlder() async throws {
        let controller = try await makeController()
        defer { controller.stopListening() }
        let old = TestClient(port: controller.wsPort!)
        let token = try await old.join("Ana")["token"] as! String
        let new = TestClient(port: controller.wsPort!)
        defer { new.close() }
        try await new.send(["type": "resume", "token": token])
        try await new.wait(type: "welcome")
        // The old socket is closed by the host.
        var closed = false
        do { _ = try await old.wait(type: "never", timeout: .seconds(3)) } catch { closed = true }
        #expect(closed)
        #expect(controller.session.seats.last?.isConnected == true)
    }

    @Test func wrongTokenIsRejected() async throws {
        let controller = try await makeController()
        defer { controller.stopListening() }
        let client = TestClient(port: controller.wsPort!)
        defer { client.close() }
        try await client.send(["type": "resume", "token": "nope"])
        let error = try await client.wait(type: "error")
        #expect(error["code"] as? String == "unknownToken")
        #expect(controller.session.seats.count == 1)
    }

    @Test func remoteHostCommandsAreRejectedByDefault() async throws {
        let controller = try await makeController(remote: false)
        defer { controller.stopListening() }
        let ana = TestClient(port: controller.wsPort!)
        defer { ana.close() }
        try await ana.join("Ana")
        try await ana.send(["type": "host", "command": "start"])
        let error = try await ana.wait(type: "error")
        #expect(error["code"] as? String == "notAllowed")
        #expect(controller.session.game == nil)
    }

    @Test func fullGameDrivenByHostCommands() async throws {
        let controller = try await makeController(remote: true)
        defer { controller.stopListening() }
        let ana = TestClient(port: controller.wsPort!)
        let ben = TestClient(port: controller.wsPort!)
        defer { ana.close(); ben.close() }
        try await ana.join("Ana")
        try await ben.join("Ben")
        let anaID = try #require(ana.playerID)
        let benID = try #require(ben.playerID)
        let hostID = controller.hostPlayerID.uuidString
        try await ana.wait("can start") { json in
            (((json["view"] as? [String: Any])?["phase"] as? [String: Any])?["canStart"] as? Bool) == true
        }

        try await ana.send(["type": "host", "command": "start"])
        try await ana.waitForPhase("dealing")
        try await ben.waitForPhase("dealing")

        controller.cardSeen()
        try await ana.send(["type": "cardSeen"])
        try await ben.send(["type": "cardSeen"])
        try await ana.waitForPhase("clues")

        // A peek reply goes to the asker only.
        try await ben.send(["type": "peek"])
        let peek = try await ben.wait(type: "peek")
        #expect(peek["peeksLeft"] as? Int == 2)

        try await ana.send(["type": "host", "command": "endClues"])
        try await ana.waitForPhase("discussion")
        try await ana.send(["type": "host", "command": "startVoting"])
        try await ana.waitForPhase("voting")

        controller.vote(for: UUID(uuidString: anaID)!)
        try await ana.send(["type": "vote", "suspect": benID])
        try await ben.send(["type": "vote", "suspect": anaID])

        // The accused imposter, if any, gets a last guess; give up on their behalf.
        try await eventually("voting resolved") {
            if case .voting? = controller.session.game?.phase { false } else { true }
        }
        if case .lastChance(let accused)? = controller.session.game?.phase {
            switch accused.uuidString {
            case hostID: controller.guess(nil)
            case anaID: try await ana.send(["type": "guess"])
            default: try await ben.send(["type": "guess"])
            }
        }
        try await eventually("finished") {
            if case .finished? = controller.session.game?.phase { true } else { false }
        }
        try await ana.waitForPhase("finished")
        try await ben.waitForPhase("finished")
        #expect(controller.wordPicker != WordPicker())
    }
}

import Foundation
import Testing
@testable import ImposterKit

/// Encodes every player's view in every phase and checks that no secret leaks.
struct HostPrivacyTests {
    typealias F = HostFixtures

    private func json(_ message: ServerMessage) throws -> String {
        String(decoding: try JSONEncoder().encode(message), as: UTF8.self)
    }

    private func strings(of face: CardFace) -> [String] {
        switch face {
        case .word(let word): [word]
        case .imposter(let hint): hint.map { [$0] } ?? []
        }
    }

    /// Checks every seat's view. Returns the encoded JSON per seat for extra assertions.
    @discardableResult
    private func assertNoLeaks(_ session: HostSession, _ label: String) throws -> [Player.ID: String] {
        var encoded: [Player.ID: String] = [:]
        let card = session.game?.round.card
        let secrets = card.map { [$0.word] + $0.hints + $0.decoys } ?? []

        for seat in session.seats {
            let view = session.view(for: seat.player.id, now: F.t0)
            let text = try json(.state(view))
            encoded[seat.player.id] = text

            var finished = false
            var allowed: [String] = []
            switch view.phase {
            case .finished: finished = true
            case .dealing(_, _, let face?, _, _): allowed = strings(of: face)
            default: break
            }

            if finished {
                #expect(text.contains(card?.word ?? "?"), "\(label): finished should reveal the word")
                continue
            }
            for secret in secrets where allowed.contains(secret) == false {
                #expect(text.contains(secret) == false, "\(label): \(seat.player.name) saw \(secret)")
            }
            for key in ["\"imposters\"", "\"ballots\"", "\"troll\"", "\"suspect\"", "\"roles\"", "\"role\"", "\"word\""] where allowed.isEmpty {
                #expect(text.contains(key) == false, "\(label): \(seat.player.name) saw \(key)")
            }
        }
        return encoded
    }

    @Test(arguments: [GameSettings.ImposterIntel.nothing, .hint, .decoy])
    func noPhaseLeaksSecrets(intel: GameSettings.ImposterIntel) throws {
        let settings = GameSettings(imposterIntel: intel, turnSeconds: 30, discussionSeconds: 120)

        try assertNoLeaks(F.lobby(), "lobby")

        var session = try F.started(settings: settings)
        try assertNoLeaks(session, "dealing")
        let ids = session.players.map(\.id)
        session.cardSeen(by: ids[0])
        session.cardSeen(by: ids[2])
        try assertNoLeaks(session, "dealing, some seen")
        for id in ids { session.cardSeen(by: id) }

        try assertNoLeaks(session, "clues")
        session.clueDone(by: session.host.player.id)
        try assertNoLeaks(session, "clues, turn 2")
        session.endClues()
        try assertNoLeaks(session, "discussion")

        session.startVoting()
        try assertNoLeaks(session, "voting, nobody voted")
        session.vote(by: ids[1], for: ids[0])
        session.vote(by: ids[2], for: ids[0])
        try assertNoLeaks(session, "voting, some voted")

        // Peeks are used before the last chance to prove they leave no trace in the state.
        for id in ids { _ = try? session.peek(by: id) }
        try assertNoLeaks(session, "voting after peeks")

        var lastChance = try F.inVoting(settings: settings)
        let imposter = try F.imposter(in: lastChance)
        F.voteFor(imposter, in: &lastChance)
        guard case .lastChance? = lastChance.game?.phase else {
            Issue.record("expected last chance")
            return
        }
        try assertNoLeaks(lastChance, "last chance")
        lastChance.guess(by: imposter, text: nil)
        try assertNoLeaks(lastChance, "finished")
    }

    @Test func dealingFaceIsOnlyForTheOwnerWhileUnseen() throws {
        var session = try F.started(settings: GameSettings(imposterIntel: .decoy))
        let round = try #require(session.game?.round)
        let ids = session.players.map(\.id)

        for id in ids {
            guard case .dealing(_, _, let face, _, _) = session.view(for: id).phase else {
                Issue.record("expected dealing")
                return
            }
            #expect(face == round.role(of: id)?.cardFace)
        }

        session.cardSeen(by: ids[1])
        guard case .dealing(_, _, let face, _, _) = session.view(for: ids[1]).phase else { return }
        #expect(face == nil)
    }

    @Test func anUndercoverCardIsIndistinguishableFromACrewCard() throws {
        let session = try F.started(settings: GameSettings(imposterIntel: .decoy))
        let round = try #require(session.game?.round)
        let imposter = try F.imposter(in: session)

        let face = try #require({ () -> CardFace? in
            if case .dealing(_, _, let face, _, _) = session.view(for: imposter).phase { return face }
            return nil
        }())
        #expect(face == .word(try #require(round.card.decoys.first)))
        #expect(round.role(of: imposter)?.isImposter == true)
    }

    @Test func finishedRevealsEverything() throws {
        var session = try F.inVoting()
        let imposter = try F.imposter(in: session)
        F.voteFor(imposter, in: &session)
        session.guess(by: imposter, text: nil)

        let text = try json(.state(session.view(for: session.host.player.id)))
        #expect(text.contains("Quokkaburger") || text.contains("Zeppelinsoup"))
        #expect(text.contains("\"imposters\""))
        #expect(text.contains("\"ballots\":["))
        #expect(text.contains(imposter.uuidString))
    }

    @Test func peekRepliesCarryTheFaceAndNothingElse() throws {
        var session = try F.inClues(settings: GameSettings(imposterIntel: .hint))
        let imposter = try F.imposter(in: session)
        let face = try session.peek(by: imposter)
        let text = try json(.peek(face: face, peeksLeft: session.peeksLeft(for: imposter)))
        #expect(text.contains("\"kind\":\"imposter\""))
        #expect(text.contains("\"peeksLeft\":2"))

        // The regular state never carries it.
        let state = try json(.state(session.view(for: imposter)))
        #expect(state.contains("\"face\"") == false)
        #expect(state.contains("Hintzilla") == false && state.contains("Hintorama") == false)
    }

    @Test func errorAndWelcomeMessagesCarryNoGameData() throws {
        let session = try F.started()
        let welcome = try json(.welcome(playerID: session.seats[1].player.id, token: session.seats[1].token))
        let error = try json(.error(.roundInProgress))
        for text in [welcome, error] {
            #expect(text.contains("Quokkaburger") == false && text.contains("Zeppelinsoup") == false)
        }
    }
}

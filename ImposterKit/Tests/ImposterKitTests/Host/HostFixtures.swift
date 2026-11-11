import Foundation
import Testing
@testable import ImposterKit

enum HostFixtures {
    static let secretCard = WordCard(word: "Quokkaburger", hints: ["Hintzilla"], decoys: ["Decoyberry"])
    static let otherCard = WordCard(word: "Zeppelinsoup", hints: ["Hintorama"], decoys: ["Decoyplum"])

    static let library = WordLibrary(categories: [
        WordCategory(id: "food", name: "Food", symbol: "🍕", cards: [secretCard, otherCard]),
    ])

    static let t0 = Date(timeIntervalSince1970: 1_000)

    static func rules(_ settings: GameSettings = GameSettings(turnSeconds: 30, discussionSeconds: 120)) -> HouseRules {
        HouseRules(settings: settings, categoryIDs: ["food"])
    }

    /// A lobby with the host ("Ryu") plus `count - 1` guests.
    static func lobby(players count: Int = 4, seed: UInt64 = 7) throws -> HostSession {
        var generator = SeededGenerator(seed: seed)
        var session = try HostSession(hostName: Fixtures.names[0], using: &generator)
        for name in Fixtures.names.dropFirst().prefix(count - 1) {
            try session.join(name: name, using: &generator)
        }
        return session
    }

    /// A started game, still dealing.
    static func started(
        players count: Int = 4,
        settings: GameSettings = GameSettings(turnSeconds: 30, discussionSeconds: 120),
        seed: UInt64 = 7
    ) throws -> HostSession {
        var session = try lobby(players: count, seed: seed)
        var generator = SeededGenerator(seed: seed &+ 100)
        try session.start(rules: rules(settings), library: library, now: t0, using: &generator)
        return session
    }

    /// Everyone has seen their card, so clues are running.
    static func inClues(players count: Int = 4, settings: GameSettings = GameSettings(turnSeconds: 30, discussionSeconds: 120)) throws -> HostSession {
        var session = try started(players: count, settings: settings)
        for id in session.players.map(\.id) { session.cardSeen(by: id, now: t0) }
        return session
    }

    static func inDiscussion(players count: Int = 4, settings: GameSettings = GameSettings(turnSeconds: 30, discussionSeconds: 120)) throws -> HostSession {
        var session = try inClues(players: count, settings: settings)
        session.endClues(now: t0)
        return session
    }

    static func inVoting(players count: Int = 4, settings: GameSettings = GameSettings(turnSeconds: 30, discussionSeconds: 120)) throws -> HostSession {
        var session = try inDiscussion(players: count, settings: settings)
        session.startVoting()
        return session
    }

    static func imposter(in session: HostSession) throws -> Player.ID {
        try #require(session.game?.round.imposterIDs.first)
    }

    static func crew(in session: HostSession) throws -> [Player.ID] {
        let round = try #require(session.game?.round)
        return round.players.map(\.id).filter { round.isImposter($0) == false }
    }

    /// Everyone votes for `target`, who votes for someone else. Ends in the last-chance guess when `target` is an imposter.
    static func voteFor(_ target: Player.ID, in session: inout HostSession) {
        let ids = session.players.map(\.id)
        for id in ids where id != target { session.vote(by: id, for: target) }
        if let other = ids.first(where: { $0 != target }) { session.vote(by: target, for: other) }
    }
}

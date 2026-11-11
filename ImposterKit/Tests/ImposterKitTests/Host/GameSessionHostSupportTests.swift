import Testing
@testable import ImposterKit

/// The engine changes that host mode relies on: `finishDeal`, `castBallot` and `nextRound(players:)`.
struct GameSessionHostSupportTests {
    private func session(players: Int = 4, settings: GameSettings = GameSettings(), seed: UInt64 = 1) throws -> GameSession {
        var generator = SeededGenerator(seed: seed)
        return try GameSession(
            players: Fixtures.players(players),
            rules: HouseRules(settings: settings, categoryIDs: ["food"]),
            library: HostFixtures.library,
            using: &generator
        )
    }

    private func voting(players: Int = 4) throws -> GameSession {
        var session = try session(players: players)
        session.finishDeal()
        session.endClues()
        session.startVoting()
        return session
    }

    // MARK: finishDeal

    @Test func finishDealJumpsStraightToClues() throws {
        var session = try session()
        session.finishDeal()
        #expect(session.phase == .clues(lap: 1, turn: 0))
    }

    @Test func finishDealIsIgnoredOutsideTheDeal() throws {
        var session = try session()
        session.finishDeal()
        session.clueGiven()
        session.finishDeal()
        #expect(session.phase == .clues(lap: 1, turn: 1))
    }

    // MARK: castBallot

    @Test func ballotsCanBeCastInAnyOrder() throws {
        var session = try voting()
        let ids = session.round.players.map(\.id)

        session.castBallot(by: ids[3], for: ids[0])
        session.castBallot(by: ids[1], for: ids[0])

        guard case .voting(let tally) = session.phase else {
            Issue.record("expected voting")
            return
        }
        #expect(tally.ballots == [ids[3]: ids[0], ids[1]: ids[0]])
    }

    @Test func castBallotRejectsSelfVotesDoubleVotesAndNonMembers() throws {
        var session = try voting()
        let ids = session.round.players.map(\.id)
        let outsider = Fixtures.players(5)[4].id

        session.castBallot(by: ids[0], for: ids[0])
        session.castBallot(by: outsider, for: ids[0])
        session.castBallot(by: ids[0], for: outsider)
        guard case .voting(let empty) = session.phase else { return }
        #expect(empty.ballots.isEmpty)

        session.castBallot(by: ids[0], for: ids[1])
        session.castBallot(by: ids[0], for: ids[2])
        guard case .voting(let tally) = session.phase else { return }
        #expect(tally.ballots == [ids[0]: ids[1]])
    }

    @Test func castBallotIsIgnoredOutsideVoting() throws {
        var session = try session()
        let ids = session.round.players.map(\.id)
        let before = session
        session.castBallot(by: ids[0], for: ids[1])
        #expect(session == before)
    }

    // MARK: nextRound(players:)

    private func finished(players: Int = 4, settings: GameSettings = GameSettings()) throws -> GameSession {
        var session = try session(players: players, settings: settings)
        session.finishDeal()
        session.endClues()
        session.accuse(nil)
        return session
    }

    @Test func nextRoundDealsToAChangedGroupAndKeepsScoresAndHistory() throws {
        var session = try finished()
        let scores = session.scoreboard
        let used = session.picker
        let group = Fixtures.players(6)

        var generator = SeededGenerator(seed: 9)
        try session.nextRound(players: group, library: HostFixtures.library, using: &generator)

        #expect(session.players == group)
        #expect(session.round.players == group)
        #expect(session.roundNumber == 2)
        #expect(session.phase == .dealing(seat: 0))
        #expect(session.scoreboard == scores)
        #expect(session.picker != used)
    }

    @Test func nextRoundFitsTheRulesToTheNewPlayerCount() throws {
        var session = try finished(players: 7, settings: GameSettings(imposterCount: 3))
        #expect(session.round.imposterIDs.count == 3)

        try session.nextRound(players: Fixtures.players(4), library: HostFixtures.library)
        #expect(session.rules.settings.imposterCount == 1)
        #expect(session.round.imposterIDs.count == 1)
    }

    @Test func nextRoundWithFewerThanThreePlayersThrows() throws {
        var session = try finished()
        #expect(throws: GameError.deal(.notEnoughPlayers(minimum: 3))) {
            try session.nextRound(players: Fixtures.players(2), library: HostFixtures.library)
        }
        #expect(session.roundNumber == 1)
        guard case .finished = session.phase else {
            Issue.record("should still be finished")
            return
        }
    }

    @Test func nextRoundWithPlayersWaitsForTheRoundToFinish() throws {
        var session = try session()
        try session.nextRound(players: Fixtures.players(5), library: HostFixtures.library)
        #expect(session.roundNumber == 1)
        #expect(session.players.count == 4)
    }
}

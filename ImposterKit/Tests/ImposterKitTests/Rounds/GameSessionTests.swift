import Testing
@testable import ImposterKit

struct GameSessionTests {
    static let library = WordLibrary(categories: [
        WordCategory(id: "food", name: "Food", symbol: "🍕", cards: [Fixtures.pizza, WordCard(word: "Taco", hints: ["Shell"], decoys: ["Burrito"])]),
    ])

    private func session(
        players: Int = 4,
        settings: GameSettings = GameSettings(clueRounds: 2),
        seed: UInt64 = 1
    ) throws -> GameSession {
        var generator = SeededGenerator(seed: seed)
        let rules = HouseRules(settings: settings, categoryIDs: ["food"])
        return try GameSession(players: Fixtures.players(players), rules: rules, library: Self.library, using: &generator)
    }

    /// Runs the deal and every clue so the session is in discussion.
    private func playToDiscussion(_ session: inout GameSession) {
        for _ in session.round.players { session.cardSeen() }
        while case .clues = session.phase { session.clueGiven() }
    }

    private func crewMember(in session: GameSession) throws -> Player.ID {
        try #require(session.round.players.first { session.round.isImposter($0.id) == false }).id
    }

    // MARK: Starting

    @Test func startsByDealingToTheFirstSeat() throws {
        let session = try session()

        #expect(session.phase == .dealing(seat: 0))
        #expect(session.currentDealSeat == session.round.players[0])
        #expect(session.roundNumber == 1)
        #expect(session.categorySymbol == "🍕")
        #expect(session.round.categoryName == "Food")
    }

    @Test func failsWithoutWords() {
        let rules = HouseRules(categoryIDs: ["missing"])
        #expect(throws: GameError.noWords) {
            try GameSession(players: Fixtures.players(4), rules: rules, library: Self.library)
        }
    }

    @Test func failsWithTooFewPlayers() {
        let rules = HouseRules(categoryIDs: ["food"])
        #expect(throws: GameError.deal(.notEnoughPlayers(minimum: 3))) {
            try GameSession(players: Fixtures.players(2), rules: rules, library: Self.library)
        }
    }

    @Test func fitsTooManyImpostersToTheGroup() throws {
        let session = try session(players: 3, settings: GameSettings(imposterCount: 4))
        #expect(session.round.imposterIDs.count == 1)
    }

    // MARK: Dealing and clues

    @Test func dealGoesAroundEverySeatThenStartsClues() throws {
        var session = try session(players: 3)

        session.cardSeen()
        #expect(session.phase == .dealing(seat: 1))
        session.cardSeen()
        session.cardSeen()

        #expect(session.phase == .clues(lap: 1, turn: 0))
        #expect(session.currentCluegiver?.id == session.round.turnOrder[0])
    }

    @Test func cluesGoAroundForEveryLapThenDiscussionStarts() throws {
        var session = try session(players: 3, settings: GameSettings(clueRounds: 2))
        for _ in 0..<3 { session.cardSeen() }

        var visited: [GameSession.Phase] = []
        while case .clues = session.phase {
            visited.append(session.phase)
            session.clueGiven()
        }

        #expect(visited == [
            .clues(lap: 1, turn: 0), .clues(lap: 1, turn: 1), .clues(lap: 1, turn: 2),
            .clues(lap: 2, turn: 0), .clues(lap: 2, turn: 1), .clues(lap: 2, turn: 2),
        ])
        #expect(session.phase == .discussion)
    }

    @Test func cluesCanBeCutShort() throws {
        var session = try session()
        for _ in 0..<4 { session.cardSeen() }
        session.endClues()

        #expect(session.phase == .discussion)
    }

    @Test func actionsOutOfPhaseDoNothing() throws {
        var session = try session()
        let before = session

        session.clueGiven()
        session.finishVoting()
        session.submitGuess("Pizza")
        session.castVote(by: session.round.players[0].id, for: session.round.players[1].id)

        #expect(session == before)
    }

    // MARK: Voting

    @Test func votersArePassedTheirTurnInSeatingOrder() throws {
        var session = try session(players: 3)
        playToDiscussion(&session)
        session.startVoting()
        let seats = session.round.players

        #expect(session.nextVoter == seats[0])
        session.castVote(by: seats[1].id, for: seats[0].id)
        #expect(session.nextVoter == seats[0], "Votes out of turn are ignored")

        session.castVote(by: seats[0].id, for: seats[1].id)
        #expect(session.nextVoter == seats[1])
    }

    @Test func catchingTheImposterOffersALastChance() throws {
        var session = try session(players: 3)
        playToDiscussion(&session)
        let imposter = try #require(session.round.imposterIDs.first)
        let seats = session.round.players

        session.startVoting()
        for voter in seats {
            let suspect = voter.id == imposter ? try #require(seats.first { $0.id != imposter }).id : imposter
            session.castVote(by: voter.id, for: suspect)
        }
        session.finishVoting()

        #expect(session.phase == .lastChance(accused: imposter))
    }

    @Test func rightGuessStealsTheWinAndScores() throws {
        var session = try session()
        playToDiscussion(&session)
        let imposter = try #require(session.round.imposterIDs.first)
        let word = session.round.card.word

        session.accuse(imposter)
        session.submitGuess(word)

        guard case .finished(let result) = session.phase else {
            Issue.record("Expected the round to finish, got \(session.phase)")
            return
        }
        #expect(result.outcome == .imposterStoleWin(caught: imposter, guess: word))
        #expect(result.awards == [imposter: 2])
        #expect(session.scoreboard.points(for: imposter) == 2)
    }

    @Test func wrongAccusationFinishesStraightAway() throws {
        var session = try session()
        playToDiscussion(&session)
        let crew = try crewMember(in: session)

        session.accuse(crew)

        guard case .finished(let result) = session.phase else {
            Issue.record("Expected the round to finish, got \(session.phase)")
            return
        }
        #expect(result.outcome == .impostersWin(accused: crew))
        #expect(result.tally == nil)
    }

    @Test func secretBallotsEarnCorrectVoteBonuses() throws {
        var session = try session(players: 4, settings: GameSettings(lastChanceGuess: false))
        playToDiscussion(&session)
        let imposter = try #require(session.round.imposterIDs.first)
        let crew = session.round.players.filter { $0.id != imposter }

        session.startVoting()
        for voter in session.round.players {
            session.castVote(by: voter.id, for: voter.id == imposter ? crew[0].id : imposter)
        }
        session.finishVoting()

        guard case .finished(let result) = session.phase else {
            Issue.record("Expected the round to finish, got \(session.phase)")
            return
        }
        #expect(result.outcome == .crewWins(caught: imposter))
        #expect(crew.allSatisfy { result.awards[$0.id] == 2 })
    }

    // MARK: Next round

    @Test func nextRoundKeepsScoresAndDealsAFreshWord() throws {
        var session = try session()
        var generator = SeededGenerator(seed: 2)
        let firstWord = session.round.card.word
        playToDiscussion(&session)
        session.accuse(nil)
        let pointsAfterFirst = session.scoreboard.points

        try session.nextRound(library: Self.library, using: &generator)

        #expect(session.roundNumber == 2)
        #expect(session.phase == .dealing(seat: 0))
        #expect(session.round.card.word != firstWord, "The picker shouldn't repeat a word while others are unused")
        #expect(session.scoreboard.points == pointsAfterFirst)
    }

    @Test func nextRoundWaitsForTheRoundToFinish() throws {
        var session = try session()
        try session.nextRound(library: Self.library)

        #expect(session.roundNumber == 1)
    }
}

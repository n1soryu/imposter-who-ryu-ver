import Testing
@testable import ImposterKit

struct RoundDealerTests {
    // MARK: Validation

    @Test("Fewer than three players can't play", arguments: [0, 1, 2])
    func rejectsSmallGroups(count: Int) {
        #expect(throws: DealError.notEnoughPlayers(minimum: 3)) {
            try Fixtures.deal(players: Fixtures.players(count))
        }
    }

    @Test func rejectsDuplicatePlayers() {
        let ryu = Player(name: "Ryu")
        #expect(throws: DealError.duplicatePlayers) {
            try Fixtures.deal(players: [ryu, ryu, Player(name: "Aiko")])
        }
    }

    @Test("Imposter count must leave the crew a majority", arguments: [0, 3, 10])
    func rejectsInvalidImposterCount(count: Int) {
        #expect(throws: DealError.invalidImposterCount(allowed: 1...2)) {
            try Fixtures.deal(players: Fixtures.players(5), settings: GameSettings(imposterCount: count))
        }
    }

    // MARK: Roles

    @Test("Deals exactly the requested number of imposters", arguments: [(3, 1), (5, 2), (8, 3), (12, 5)])
    func dealsRequestedImposters(players: Int, imposters: Int) throws {
        let round = try Fixtures.deal(players: Fixtures.players(players), settings: GameSettings(imposterCount: imposters))

        #expect(round.roles.count == players)
        #expect(round.imposterIDs.count == imposters)
        #expect(round.isTrollRound == false)
    }

    @Test func crewSeeTheSecretWord() throws {
        let round = try Fixtures.deal()
        let crewRoles = round.roles.values.filter { $0.isImposter == false }

        #expect(crewRoles.count == 4)
        #expect(crewRoles.allSatisfy { $0 == .crew(word: "Pizza") })
    }

    @Test func classicImposterSeesNothing() throws {
        let round = try Fixtures.deal()
        let imposter = try #require(round.imposterIDs.first)

        #expect(round.role(of: imposter) == .imposter(hint: nil))
        #expect(round.role(of: imposter)?.cardFace == .imposter(hint: nil))
    }

    @Test(arguments: 1...20 as ClosedRange<UInt64>)
    func hintModeGivesOneOfTheCardsHints(seed: UInt64) throws {
        let round = try Fixtures.deal(settings: GameSettings(imposterIntel: .hint), seed: seed)
        let imposter = try #require(round.imposterIDs.first)

        guard case .imposter(let hint) = round.role(of: imposter) else {
            Issue.record("Expected an imposter role, got \(String(describing: round.role(of: imposter)))")
            return
        }
        let unwrapped = try #require(hint)
        #expect(Fixtures.pizza.hints.contains(unwrapped))
    }

    @Test func hintModeWithoutHintsFallsBackToNothing() throws {
        let round = try Fixtures.deal(card: Fixtures.bareCard, settings: GameSettings(imposterIntel: .hint))
        let imposter = try #require(round.imposterIDs.first)

        #expect(round.role(of: imposter) == .imposter(hint: nil))
    }

    @Test func undercoverImposterHoldsADecoyThatLooksLikeACrewCard() throws {
        let round = try Fixtures.deal(settings: GameSettings(imposterIntel: .decoy))
        let imposter = try #require(round.imposterIDs.first)

        #expect(round.role(of: imposter) == .undercover(decoy: "Calzone"))
        #expect(round.role(of: imposter)?.cardFace == .word("Calzone"))
    }

    @Test func decoyModeWithoutDecoysFallsBackToAHint() throws {
        let card = WordCard(word: "Pizza", hints: ["Slice"])
        let round = try Fixtures.deal(card: card, settings: GameSettings(imposterIntel: .decoy))
        let imposter = try #require(round.imposterIDs.first)

        #expect(round.role(of: imposter) == .imposter(hint: "Slice"))
    }

    // MARK: Troll rounds

    @Test func certainTrollChanceMakesEveryoneAnImposter() throws {
        let round = try Fixtures.deal(settings: GameSettings(trollChance: 1))

        #expect(round.isTrollRound)
        #expect(round.imposterIDs.count == round.players.count)
    }

    @Test func trollRoundsNeverHandOutDecoys() throws {
        let round = try Fixtures.deal(settings: GameSettings(imposterIntel: .decoy, trollChance: 1))

        #expect(round.roles.values.allSatisfy { if case .imposter = $0 { true } else { false } })
    }

    @Test(arguments: 1...50 as ClosedRange<UInt64>)
    func zeroTrollChanceNeverTrolls(seed: UInt64) throws {
        let round = try Fixtures.deal(settings: GameSettings(trollChance: 0), seed: seed)
        #expect(round.isTrollRound == false)
    }

    // MARK: Turn order

    @Test(arguments: 1...50 as ClosedRange<UInt64>)
    func imposterNeverGoesFirstByDefault(seed: UInt64) throws {
        let round = try Fixtures.deal(players: Fixtures.players(3), seed: seed)
        let first = try #require(round.turnOrder.first)

        #expect(round.isImposter(first) == false)
    }

    @Test func imposterCanGoFirstWhenAllowed() throws {
        let settings = GameSettings(imposterMayStart: true)
        let imposterStarts = try (1...100 as ClosedRange<UInt64>).contains { seed in
            let round = try Fixtures.deal(players: Fixtures.players(3), settings: settings, seed: seed)
            return round.isImposter(round.turnOrder[0])
        }

        #expect(imposterStarts, "With 100 seeds and a 1-in-3 chance, an imposter should start at least once")
    }

    @Test(arguments: 1...20 as ClosedRange<UInt64>)
    func turnOrderFollowsSeatingFromTheStarter(seed: UInt64) throws {
        let players = Fixtures.players(6)
        let round = try Fixtures.deal(players: players, seed: seed)
        let start = try #require(players.firstIndex { $0.id == round.turnOrder.first })
        let expected = (players[start...] + players[..<start]).map(\.id)

        #expect(round.turnOrder == expected)
    }

    // MARK: Determinism

    @Test func sameSeedDealsTheSameRound() throws {
        let players = Fixtures.players(7)
        let settings = GameSettings(imposterCount: 2, imposterIntel: .hint, trollChance: 0.2)

        let first = try Fixtures.deal(players: players, settings: settings, seed: 42)
        let second = try Fixtures.deal(players: players, settings: settings, seed: 42)

        #expect(first == second)
    }
}

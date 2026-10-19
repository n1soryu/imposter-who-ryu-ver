import Testing
@testable import ImposterKit

struct ScoreboardTests {
    let round: Round
    let imposter: Player.ID
    let crew: [Player.ID]

    init() throws {
        let round = try Fixtures.deal()
        let imposter = try #require(round.imposterIDs.first)
        self.round = round
        self.imposter = imposter
        crew = round.players.map(\.id).filter { $0 != imposter }
    }

    @Test func crewWinPaysEveryCrewMember() {
        let awards = Scoreboard().awards(for: round, outcome: .crewWins(caught: imposter))

        #expect(awards == Dictionary(uniqueKeysWithValues: crew.map { ($0, 1) }))
    }

    @Test func correctVotersEarnABonus() {
        var tally = VoteTally()
        tally.cast(by: crew[0], for: imposter)
        tally.cast(by: crew[1], for: imposter)
        tally.cast(by: crew[2], for: crew[3])

        let awards = Scoreboard().awards(for: round, outcome: .crewWins(caught: imposter), tally: tally)

        #expect(awards[crew[0]] == 2)
        #expect(awards[crew[1]] == 2)
        #expect(awards[crew[2]] == 1)
        #expect(awards[imposter] == nil)
    }

    @Test(arguments: [
        RoundOutcome.impostersWin(accused: nil),
        .imposterStoleWin(caught: UUIDs.placeholder, guess: "Pizza"),
    ])
    func imposterWinPaysOnlyImposters(outcome: RoundOutcome) {
        let awards = Scoreboard().awards(for: round, outcome: outcome)
        #expect(awards == [imposter: 2])
    }

    @Test func trollRoundPaysNobody() {
        #expect(Scoreboard().awards(for: round, outcome: .trollRound(accused: nil)).isEmpty)
    }

    @Test func customRulesChangeThePayout() {
        let rules = ScoringRules(crewWin: 3, correctVote: 0, imposterWin: 5)
        #expect(Scoreboard(rules: rules).awards(for: round, outcome: .impostersWin(accused: nil)) == [imposter: 5])
    }

    @Test func recordingAccumulatesAcrossRounds() {
        var board = Scoreboard()
        board.record(round, outcome: .crewWins(caught: imposter))
        board.record(round, outcome: .impostersWin(accused: crew[0]))

        #expect(board.roundsPlayed == 2)
        #expect(board.points(for: crew[0]) == 1)
        #expect(board.points(for: imposter) == 2)
    }

    @Test func standingsRankByPointsThenSeating() {
        var board = Scoreboard()
        board.record(round, outcome: .impostersWin(accused: nil))
        let standings = board.standings(for: round.players)

        #expect(standings.first?.player.id == imposter)
        #expect(standings.dropFirst().map(\.player.id) == crew)
    }
}

enum UUIDs {
    static let placeholder = Player(name: "Placeholder").id
}

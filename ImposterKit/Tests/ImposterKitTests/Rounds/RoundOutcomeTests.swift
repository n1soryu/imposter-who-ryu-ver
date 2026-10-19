import Testing
@testable import ImposterKit

struct RoundOutcomeTests {
    let round: Round
    let imposter: Player.ID
    let crewMember: Player.ID

    init() throws {
        let round = try Fixtures.deal()
        self.round = round
        imposter = try #require(round.imposterIDs.first)
        crewMember = try #require(round.players.first { round.isImposter($0.id) == false }?.id)
    }

    @Test func catchingTheImposterWinsForTheCrew() {
        let outcome = round.outcome(accused: imposter, guess: "Burger")

        #expect(outcome == .crewWins(caught: imposter))
        #expect(outcome.crewWon)
    }

    @Test func accusingACrewMemberLetsTheImposterWin() {
        let outcome = round.outcome(accused: crewMember)

        #expect(outcome == .impostersWin(accused: crewMember))
        #expect(outcome.impostersWon)
    }

    @Test func tiedVoteLetsTheImposterWin() {
        #expect(round.outcome(accused: nil) == .impostersWin(accused: nil))
    }

    @Test func caughtImposterStealsTheWinWithTheRightWord() {
        #expect(round.offersLastChanceGuess(to: imposter))
        #expect(round.outcome(accused: imposter, guess: "pizza") == .imposterStoleWin(caught: imposter, guess: "pizza"))
    }

    @Test func onlyACaughtImposterGetsALastChance() {
        #expect(round.offersLastChanceGuess(to: crewMember) == false)
        #expect(round.offersLastChanceGuess(to: nil) == false)
    }

    @Test func lastChanceGuessCanBeTurnedOff() throws {
        let strict = try Fixtures.deal(settings: GameSettings(lastChanceGuess: false))
        let imposter = try #require(strict.imposterIDs.first)

        #expect(strict.offersLastChanceGuess(to: imposter) == false)
        #expect(strict.outcome(accused: imposter, guess: "Pizza") == .crewWins(caught: imposter))
    }

    @Test func trollRoundsEndAsTrollRoundsWhoeverIsAccused() throws {
        let troll = try Fixtures.deal(settings: GameSettings(trollChance: 1))
        let anyone = try #require(troll.players.first?.id)

        #expect(troll.offersLastChanceGuess(to: anyone) == false)
        #expect(troll.outcome(accused: anyone, guess: "Pizza") == .trollRound(accused: anyone))
        #expect(troll.outcome(accused: anyone).crewWon == false)
        #expect(troll.outcome(accused: anyone).impostersWon == false)
    }
}

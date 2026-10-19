import Testing
@testable import ImposterKit

struct VoteTallyTests {
    let players = Fixtures.players(4)

    @Test func playersCannotVoteForThemselves() {
        var tally = VoteTally()
        let accepted = tally.cast(by: players[0].id, for: players[0].id)

        #expect(accepted == false)
        #expect(tally.hasVoted(players[0].id) == false)
    }

    @Test func votingAgainReplacesTheEarlierVote() {
        var tally = VoteTally()
        tally.cast(by: players[0].id, for: players[1].id)
        tally.cast(by: players[0].id, for: players[2].id)

        #expect(tally.ballots == [players[0].id: players[2].id])
    }

    @Test func mostVotesIsAccused() {
        var tally = VoteTally()
        tally.cast(by: players[0].id, for: players[3].id)
        tally.cast(by: players[1].id, for: players[3].id)
        tally.cast(by: players[2].id, for: players[0].id)
        tally.cast(by: players[3].id, for: players[0].id)
        tally.cast(by: players[2].id, for: players[3].id)

        #expect(tally.counts == [players[3].id: 3, players[0].id: 1])
        #expect(tally.accused == players[3].id)
    }

    @Test func tieAccusesNobody() {
        var tally = VoteTally()
        tally.cast(by: players[0].id, for: players[1].id)
        tally.cast(by: players[1].id, for: players[0].id)

        #expect(Set(tally.leaders) == [players[0].id, players[1].id])
        #expect(tally.accused == nil)
    }

    @Test func noVotesAccusesNobody() {
        let tally = VoteTally()
        #expect(tally.leaders.isEmpty)
        #expect(tally.accused == nil)
    }
}

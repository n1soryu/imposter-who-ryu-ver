import ImposterKit
import SwiftUI

/// Secret ballots: the phone goes around, each player votes in private, then the result is revealed.
struct VotingView: View {
    var round: Round
    /// Who should vote next, or `nil` once everyone has voted.
    var voter: Player?
    var votesCast: Int
    var cast: (_ voter: Player.ID, _ suspect: Player.ID) -> Void
    var reveal: () -> Void

    var body: some View {
        Group {
            if let voter {
                BallotTurn(
                    voter: voter,
                    candidates: round.players.filter { $0.id != voter.id },
                    progress: "Vote \(votesCast + 1) of \(round.players.count)"
                ) { suspect in
                    cast(voter.id, suspect)
                }
                .id(voter.id)
            } else {
                AllVotesInView(count: votesCast, reveal: reveal)
            }
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.felt)
    }
}

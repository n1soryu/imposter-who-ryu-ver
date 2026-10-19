import ImposterKit
import SwiftUI

/// The screen for whichever phase the round is in, wired to the matching game action.
struct GamePhaseView: View {
    var session: GameSession
    var showScoreboard: () -> Void

    @Environment(GameStore.self) private var store
    @Environment(\.wordLibrary) private var library
    @State private var isQuickVoting = false

    var body: some View {
        let round = session.round

        switch session.phase {
        case .dealing(let seat):
            let player = round.players[seat]
            DealView(
                player: player,
                role: round.role(of: player.id) ?? .crew(word: round.card.word),
                categoryName: round.categoryName,
                categorySymbol: session.categorySymbol,
                seatNumber: seat + 1,
                seatCount: round.players.count
            ) {
                perform { $0.cardSeen() }
            }
            .id(player.id)

        case .clues(let lap, let turn):
            CluesView(round: round, lap: lap, turn: turn) {
                perform { $0.clueGiven() }
            } skipToDiscussion: {
                perform { $0.endClues() }
            }

        case .discussion:
            DiscussionView(seconds: session.rules.settings.discussionSeconds) {
                perform { $0.startVoting() }
            } quickVote: {
                isQuickVoting = true
            }
            .sheet(isPresented: $isQuickVoting) {
                QuickAccuseView(players: round.players) { accused in
                    perform { $0.accuse(accused) }
                }
            }

        case .voting(let tally):
            VotingView(round: round, voter: session.nextVoter, votesCast: tally.ballots.count) { voter, suspect in
                perform { $0.castVote(by: voter, for: suspect) }
            } reveal: {
                perform { $0.finishVoting() }
            }

        case .lastChance(let accused):
            LastChanceView(imposterName: round.player(accused)?.name ?? "The imposter") { guess in
                perform { $0.submitGuess(guess) }
            }

        case .finished(let result):
            ResultsView(session: session, result: result, nextRound: nextRound, showScoreboard: showScoreboard)
                .id(session.roundNumber)
        }
    }

    private func perform(_ action: (inout GameSession) -> Void) {
        withAnimation(.snappy) { store.perform(action) }
    }

    private func nextRound() {
        withAnimation(.snappy) { store.nextRound(library: library) }
    }
}

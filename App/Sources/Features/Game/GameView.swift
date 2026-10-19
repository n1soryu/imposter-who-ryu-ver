import ImposterKit
import SwiftUI

/// Hosts a game in progress and shows the screen for the current phase.
struct GameView: View {
    var leave: () -> Void

    @Environment(GameStore.self) private var store
    @State private var isConfirmingEnd = false
    @State private var isQuickVoting = false
    @State private var isShowingScoreboard = false
    @Environment(\.wordLibrary) private var library

    var body: some View {
        Group {
            if let session = store.session {
                phaseView(for: session)
            } else {
                Color.felt.onAppear(perform: leave)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("End game") { isConfirmingEnd = true }
            }
        }
        .confirmationDialog("End this game?", isPresented: $isConfirmingEnd, titleVisibility: .visible) {
            Button("End game", role: .destructive) {
                store.end()
                leave()
            }
        } message: {
            Text("Scores from this game won't be kept.")
        }
    }

    @ViewBuilder
    private func phaseView(for session: GameSession) -> some View {
        switch session.phase {
        case .dealing(let seat):
            let player = session.round.players[seat]
            DealView(
                player: player,
                role: session.round.role(of: player.id) ?? .crew(word: session.round.card.word),
                categoryName: session.round.categoryName,
                categorySymbol: session.categorySymbol,
                seatNumber: seat + 1,
                seatCount: session.round.players.count
            ) {
                withAnimation(.snappy) { store.perform { $0.cardSeen() } }
            }
            .id(player.id)
        case .clues(let lap, let turn):
            CluesView(round: session.round, lap: lap, turn: turn) {
                withAnimation(.snappy) { store.perform { $0.clueGiven() } }
            } skipToDiscussion: {
                withAnimation(.snappy) { store.perform { $0.endClues() } }
            }
        case .discussion:
            DiscussionView(seconds: session.rules.settings.discussionSeconds) {
                withAnimation(.snappy) { store.perform { $0.startVoting() } }
            } quickVote: {
                isQuickVoting = true
            }
            .sheet(isPresented: $isQuickVoting) {
                QuickAccuseView(players: session.round.players) { accused in
                    withAnimation(.snappy) { store.perform { $0.accuse(accused) } }
                }
                .presentationDetents([.large])
            }
        case .voting(let tally):
            VotingView(round: session.round, voter: session.nextVoter, votesCast: tally.ballots.count) { voter, suspect in
                withAnimation(.snappy) { store.perform { $0.castVote(by: voter, for: suspect) } }
            } reveal: {
                withAnimation(.snappy) { store.perform { $0.finishVoting() } }
            }
        case .lastChance(let accused):
            if let imposter = session.round.player(accused) {
                LastChanceView(imposter: imposter) { guess in
                    withAnimation(.snappy) { store.perform { $0.submitGuess(guess) } }
                }
            }
        case .finished(let result):
            ResultsView(session: session, result: result) {
                withAnimation(.snappy) { store.nextRound(library: library) }
            } showScoreboard: {
                isShowingScoreboard = true
            }
            .id(session.roundNumber)
        }
    }
}

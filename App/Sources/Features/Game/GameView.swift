import ImposterKit
import SwiftUI

/// Hosts a game in progress: the current phase, the scoreboard, and ending the game.
struct GameView: View {
    var leave: () -> Void

    @Environment(GameStore.self) private var store
    @State private var isConfirmingEnd = false
    @State private var isShowingScoreboard = false

    var body: some View {
        @Bindable var store = store

        Group {
            if let session = store.session {
                GamePhaseView(session: session, showScoreboard: showScoreboard)
            } else {
                Color.felt.onAppear(perform: leave)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("End game", action: confirmEnd)
                    .confirmationDialog("End this game?", isPresented: $isConfirmingEnd, titleVisibility: .visible) {
                        Button("End game", role: .destructive, action: endGame)
                    } message: {
                        Text(endMessage)
                    }
            }
        }
        .sheet(isPresented: $isShowingScoreboard) {
            if let session = store.session {
                ScoreboardView(session: session)
            }
        }
        .alert("Couldn't deal the next round", item: $store.problem) { _ in
        } message: { problem in
            Text(problem)
        }
    }

    private var endMessage: String {
        guard let session = store.session, session.scoreboard.roundsPlayed > 0,
              let leader = session.scoreboard.standings(for: session.players).first
        else { return "No rounds have been finished yet." }
        return "\(leader.player.name) is leading with \(leader.points) points. Scores aren't kept after the game ends."
    }

    private func confirmEnd() {
        isConfirmingEnd = true
    }

    private func showScoreboard() {
        isShowingScoreboard = true
    }

    private func endGame() {
        store.end()
        leave()
    }
}

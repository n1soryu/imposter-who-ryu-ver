import ImposterHost
import SwiftUI

/// A hosted game in progress: the host's phase screen, the scoreboard, the player list, and leaving.
struct HostGameView: View {
    var backToLobby: () -> Void
    var leave: () -> Void

    @Environment(HostStore.self) private var host
    @State private var isConfirmingLeave = false
    @State private var isShowingScoreboard = false
    @State private var isShowingPlayers = false

    var body: some View {
        @Bindable var host = host

        Group {
            if let controller = host.controller {
                HostPhaseView(controller: controller, showScoreboard: showScoreboard, backToLobby: backToLobby)
            } else {
                Color.felt.onAppear(perform: leave)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Leave", action: confirmLeave)
                    .confirmationDialog("Leave this game?", isPresented: $isConfirmingLeave, titleVisibility: .visible) {
                        Button("End the game for everyone", role: .destructive, action: leave)
                    } message: {
                        Text("Leaving closes the game on every phone, and scores aren't kept.")
                    }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Players", systemImage: "person.2", action: showPlayers)
            }
        }
        .sheet(isPresented: $isShowingScoreboard) {
            if let game = host.controller?.session.game {
                ScoreboardView(session: game)
            }
        }
        .sheet(isPresented: $isShowingPlayers) {
            if let controller = host.controller {
                HostPlayersSheet(controller: controller)
            }
        }
        .alert("Couldn't deal the next round", item: $host.problem) { _ in
        } message: { problem in
            Text(problem)
        }
    }

    private func confirmLeave() {
        isConfirmingLeave = true
    }

    private func showScoreboard() {
        isShowingScoreboard = true
    }

    private func showPlayers() {
        isShowingPlayers = true
    }
}

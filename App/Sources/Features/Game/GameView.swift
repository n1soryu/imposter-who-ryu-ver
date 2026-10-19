import ImposterKit
import SwiftUI

/// Hosts a game in progress and shows the screen for the current phase.
struct GameView: View {
    var leave: () -> Void

    @Environment(GameStore.self) private var store
    @State private var isConfirmingEnd = false

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
        default:
            ContentUnavailableView(
                "Clues are next",
                systemImage: "bubble.left.and.bubble.right",
                description: Text("Everyone has their card. Clue turns, voting and results arrive in the next builds.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.felt)
        }
    }
}

import ImposterKit
import SwiftUI

/// The host's card again, for a peek that has already been counted. Face down until held.
struct PeekSheet: View {
    var face: CardFace
    var categorySymbol: String
    var peeksLeft: Int

    @State private var isRevealed = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                HoldToRevealCard(isRevealed: $isRevealed, face: face, categorySymbol: categorySymbol)
                    .frame(maxWidth: 300)
                Text("Hold the card to look. Let go to hide it.")
                    .foregroundStyle(Color.haze)
                Text(peeksLeft == 1 ? "1 peek left this round." : "\(peeksLeft) peeks left this round.")
                    .font(.footnote)
                    .foregroundStyle(Color.haze)
                Spacer()
            }
            .padding(Metrics.gutter)
            .frame(maxWidth: .infinity)
            .background(Color.felt)
            .navigationTitle("Your card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { isRevealed = false }
            }
        }
    }
}

/// One counted peek, so the sheet can be shown for it.
struct PeekedCard: Identifiable {
    let id = UUID()
    var face: CardFace
    var peeksLeft: Int
}

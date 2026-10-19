import ImposterKit
import SwiftUI

/// The player has the phone: they hold the card to peek, then pass it on.
struct PeekStep: View {
    var role: Role
    var categoryName: String
    var categorySymbol: String
    var isLastSeat: Bool
    var done: () -> Void

    @State private var isRevealed = false
    @State private var hasPeeked = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            Text("Category: \(categoryName)")
                .font(.headline)
                .foregroundStyle(Color.haze)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 24)

            HoldToRevealCard(isRevealed: $isRevealed, face: role.cardFace, categorySymbol: categorySymbol)
                .frame(maxWidth: 300)

            Spacer(minLength: 24)

            Text(hasPeeked ? "Remember it, then pass the phone on." : "Hold the card to peek. Let go to hide it.")
                .foregroundStyle(Color.haze)
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)

            Button(isLastSeat ? "Done, start the clues" : "Done, pass the phone", action: done)
                .buttonStyle(.pill)
                .disabled(hasPeeked == false)
        }
        .onChange(of: isRevealed) { _, revealed in
            if revealed { hasPeeked = true }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { isRevealed = false }
        }
    }
}

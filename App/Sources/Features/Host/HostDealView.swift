import ImposterKit
import SwiftUI

/// The host's own card: hold it to peek, then wait for everyone else to look at theirs.
struct HostDealView: View {
    var categoryName: String
    var categorySymbol: String
    /// `nil` once the host has marked their card seen.
    var face: CardFace?
    var players: [PlayerView.Participant]
    var waitingFor: [Player.ID]
    var done: () -> Void

    @State private var isRevealed = false
    @State private var hasPeeked = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        AdaptiveScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Category: \(categoryName)")
                    .font(.headline)
                    .foregroundStyle(Color.haze)

                if let face {
                    Spacer(minLength: 24)
                    HoldToRevealCard(isRevealed: $isRevealed, face: face, categorySymbol: categorySymbol)
                        .frame(maxWidth: 300)
                        .frame(maxWidth: .infinity)
                    Spacer(minLength: 24)
                    Text(hasPeeked ? "Remember it, then tell the game you're ready." : "Hold the card to peek. Let go to hide it.")
                        .foregroundStyle(Color.haze)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 16)
                    Button("I've seen my card", action: done)
                        .buttonStyle(.pill)
                        .disabled(hasPeeked == false)
                } else {
                    Text("Waiting for everyone to see their card")
                        .font(.display(40))
                        .foregroundStyle(Color.cardStock)
                        .minimumScaleFactor(0.5)
                        .padding(.top, 24)
                    HostStatusList(players: players, readyLabel: "Ready", pending: waitingFor)
                        .padding(.top, 24)
                    Spacer()
                }
            }
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.felt)
        .onChange(of: isRevealed) { _, revealed in
            if revealed { hasPeeked = true }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { isRevealed = false }
        }
    }
}

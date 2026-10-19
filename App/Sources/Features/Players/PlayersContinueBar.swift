import ImposterKit
import SwiftUI

/// The pinned button under the player list, with a note on how many more players are needed.
struct PlayersContinueBar: View {
    var playerCount: Int
    var action: () -> Void

    var body: some View {
        let needed = max(GameSettings.minimumPlayers - playerCount, 0)

        VStack(spacing: 8) {
            Button("Choose house rules", action: action)
                .buttonStyle(.pill)
                .disabled(needed > 0)
            if needed > 0 {
                Text("Add ^[\(needed) more player](inflect: true) to start.")
                    .font(.footnote)
                    .foregroundStyle(Color.haze)
            }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 12)
        .background(Color.felt)
    }
}

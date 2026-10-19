import ImposterKit
import SwiftUI

struct HomeView: View {
    var startNewGame: () -> Void

    @Environment(\.wordLibrary) private var library
    @State private var isShowingRules = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SoundToggleButton()
                .frame(maxWidth: .infinity, alignment: .trailing)

            CardFan()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 24)

            Text("Imposter")
                .font(.display(60))
                .foregroundStyle(Color.cardStock)

            Text("Everyone gets the secret word except one of you.")
                .font(.title3)
                .foregroundStyle(Color.haze)
                .padding(.top, 4)

            Text("^[\(library.cardCount) word](inflect: true) in ^[\(library.categories.count) category](inflect: true)")
                .font(.subheadline)
                .foregroundStyle(Color.haze)
                .padding(.top, 12)

            VStack(spacing: 12) {
                Button("New game", action: startNewGame)
                    .buttonStyle(.pill)
                Button("How to play", action: showRules)
                    .buttonStyle(.pillSecondary)
            }
            .padding(.top, 28)
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.felt)
        .sheet(isPresented: $isShowingRules) {
            HowToPlayView()
        }
    }

    private func showRules() {
        isShowingRules = true
    }
}

#Preview {
    NavigationStack {
        HomeView {}
    }
    .environment(\.wordLibrary, .bundledOrEmpty())
    .environment(SoundPlayer(defaults: UserDefaults(suiteName: "preview-home") ?? .standard))
}

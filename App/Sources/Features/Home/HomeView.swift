import ImposterKit
import SwiftUI

struct HomeView: View {
    var startNewGame: () -> Void

    @Environment(\.wordLibrary) private var library
    @State private var isShowingRules = false

    var body: some View {
        // The home screen always fits the phone: the card fan shrinks, or hides, to make room.
        VStack(alignment: .leading, spacing: 0) {
            SoundToggleButton()
                .frame(maxWidth: .infinity, alignment: .trailing)

            CardFan()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 16)

            Text("Imposter")
                .font(.display(60))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(Color.cardStock)

            Text("Everyone gets the secret word except one of you.")
                .font(.title3)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(Color.haze)
                .padding(.top, 4)

            Text("^[\(library.cardCount) word](inflect: true) in ^[\(library.categories.count) category](inflect: true)")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
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
        // Past this size the tagline and buttons alone are taller than the phone, so the home screen stops growing here.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
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

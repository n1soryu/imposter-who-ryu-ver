import ImposterKit
import SwiftUI

struct HomeView: View {
    var startNewGame: () -> Void

    @Environment(\.wordLibrary) private var library
    @State private var isShowingRules = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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

            Text("\(library.cardCount) words in \(library.categories.count) categories")
                .font(.subheadline)
                .foregroundStyle(Color.haze)
                .padding(.top, 12)

            VStack(spacing: 12) {
                Button("New game", action: startNewGame)
                    .buttonStyle(.pill)
                Button("How to play") { isShowingRules = true }
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
}

/// Three dealt cards: two crew cards with the same word and the imposter's card tucked between them.
private struct CardFan: View {
    var body: some View {
        ZStack {
            CrewCard(word: "Pizza", symbol: "🍕")
                .rotationEffect(.degrees(-14))
                .offset(x: -70, y: 12)
            CrewCard(word: "Pizza", symbol: "🍕")
                .rotationEffect(.degrees(13))
                .offset(x: 70, y: 16)
            ImposterCard()
                .rotationEffect(.degrees(-2))
        }
        .frame(maxWidth: 200)
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        HomeView {}
    }
    .environment(\.wordLibrary, .bundledOrEmpty())
}

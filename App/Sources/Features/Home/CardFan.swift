import SwiftUI

/// Three dealt cards: two crew cards with the same word and the imposter's card tucked between them.
struct CardFan: View {
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

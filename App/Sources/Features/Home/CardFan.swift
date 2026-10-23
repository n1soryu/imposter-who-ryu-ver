import SwiftUI

/// Three dealt cards: two crew cards with the same word and the imposter's card tucked between them.
///
/// It scales down to whatever height it's given, and hides when there's too little room to read it.
struct CardFan: View {
    /// The fan's size at full scale, including the tilted outer cards.
    private static let designSize = CGSize(width: 340, height: 310)
    private static let smallestScale = 0.35

    var body: some View {
        GeometryReader { proxy in
            let scale = min(1, proxy.size.width / Self.designSize.width, proxy.size.height / Self.designSize.height)
            if scale >= Self.smallestScale {
                fan
                    .scaleEffect(scale)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .accessibilityHidden(true)
    }

    private var fan: some View {
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
        .frame(width: 200, height: 280)
    }
}

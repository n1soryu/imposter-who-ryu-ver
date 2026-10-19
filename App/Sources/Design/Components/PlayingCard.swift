import SwiftUI

/// A risograph-printed playing card. The face ink says what kind of card it is, and a second ink is printed slightly off-register behind it.
struct PlayingCard<Content: View>: View {
    var face: Color
    var misprint: Color
    /// The small mark printed in two corners, like a playing card's index.
    var cornerMark: String
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous)

        ZStack {
            shape.fill(face)
            content
                .padding(28)
            corners
        }
        .background {
            shape
                .fill(misprint)
                .offset(x: Metrics.misprintOffset, y: Metrics.misprintOffset)
        }
        .aspectRatio(5 / 7, contentMode: .fit)
    }

    private var corners: some View {
        VStack {
            HStack {
                Text(cornerMark)
                Spacer()
            }
            Spacer()
            HStack {
                Spacer()
                Text(cornerMark).rotationEffect(.degrees(180))
            }
        }
        .font(.title3)
        .padding(16)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 24) {
        CrewCard(word: "Pizza", symbol: "🍕")
        ImposterCard()
    }
    .padding(32)
    .background(Color.felt)
}

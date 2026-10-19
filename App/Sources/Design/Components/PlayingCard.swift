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

/// The card a crew member sees: yellow, holding the secret word.
struct CrewCard: View {
    var word: String
    var symbol: String

    var body: some View {
        PlayingCard(face: .crewInk, misprint: .imposterInk, cornerMark: symbol) {
            CardWord(text: word)
        }
    }
}

/// The card an imposter sees: pink, with no secret word.
struct ImposterCard: View {
    var body: some View {
        PlayingCard(face: .imposterInk, misprint: .crewInk, cornerMark: "?") {
            CardWord(text: "Imposter")
        }
    }
}

/// The big word printed in the middle of a card.
struct CardWord: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.display(44))
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.5)
            .foregroundStyle(Color.felt)
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

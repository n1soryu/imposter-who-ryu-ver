import SwiftUI

/// The big word printed in the middle of a card. A single word shrinks to fit rather than breaking mid-word.
struct CardWord: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.display(44))
            .multilineTextAlignment(.center)
            .lineLimit(text.contains(" ") ? 3 : 1)
            .minimumScaleFactor(0.3)
            .allowsTightening(true)
            .foregroundStyle(Color.felt)
    }
}

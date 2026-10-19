import SwiftUI

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

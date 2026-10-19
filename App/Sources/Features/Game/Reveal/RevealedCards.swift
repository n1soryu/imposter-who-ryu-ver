import ImposterKit
import SwiftUI

/// The secret word card and the imposter's card, which flips over and slides out from behind it.
struct RevealedCards: View {
    var round: Round
    var symbol: String
    var isRevealed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let imposterNames = round.players.filter { round.isImposter($0.id) }.map(\.name)

        ZStack {
            CrewCard(word: round.card.word, symbol: symbol)
                .rotationEffect(.degrees(isRevealed ? -8 : 0))
                .offset(x: isRevealed ? -62 : 0)
            PlayingCard(face: .imposterInk, misprint: .crewInk, cornerMark: "?") {
                VStack(spacing: 8) {
                    Text(imposterNames.count == 1 ? "Imposter" : "Imposters")
                        .font(.subheadline.weight(.semibold))
                    Text(imposterNames.formatted())
                        .font(.display(34))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.4)
                }
                .foregroundStyle(Color.felt)
            }
            .rotationEffect(.degrees(isRevealed ? 9 : 0))
            .rotation3DEffect(.degrees(isRevealed || reduceMotion ? 0 : 90), axis: (x: 0, y: 1, z: 0))
            .offset(x: isRevealed ? 62 : 0, y: isRevealed ? 10 : 0)
            .opacity(isRevealed ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The word was \(round.card.word). \(imposterNames.formatted()) \(imposterNames.count == 1 ? "was the imposter" : "were the imposters").")
    }
}

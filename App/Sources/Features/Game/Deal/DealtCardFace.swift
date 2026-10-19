import ImposterKit
import SwiftUI

/// The face of a dealt card. Crew, undercover and imposter cards all share the same stock and ink.
struct DealtCardFace: View {
    var face: CardFace
    var symbol: String

    var body: some View {
        PlayingCard(face: .cardStock, misprint: .haze, cornerMark: symbol) {
            switch face {
            case .word(let word):
                CardWord(text: word)
            case .imposter(let hint):
                ImposterFaceContent(hint: hint)
            }
        }
    }
}

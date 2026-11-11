import SwiftUI

/// The card an imposter sees: pink, with no secret word.
struct ImposterCard: View {
    var body: some View {
        PlayingCard(face: .imposterInk, misprint: .crewInk, cornerMark: "?", ink: .cardStock) {
            CardWord(text: "Imposter", color: .cardStock)
        }
    }
}

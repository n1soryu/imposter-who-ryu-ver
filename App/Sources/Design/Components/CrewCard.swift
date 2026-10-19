import SwiftUI

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

import SwiftUI

/// The back of a dealt card.
struct CardBack: View {
    var symbol: String

    var body: some View {
        PlayingCard(face: .feltRaised, misprint: .crewInk, cornerMark: symbol) {
            Text("?")
                .font(.display(140))
                .foregroundStyle(Color.crewInk)
        }
    }
}

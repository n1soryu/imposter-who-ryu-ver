import SwiftUI

/// Tips and errors under a pack's word list.
struct PackWordsFooter: View {
    var problem: String?
    var wordCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let problem {
                Text(problem)
                    .foregroundStyle(Color.imposterInk)
            }
            if wordCount < 10 {
                Text("Packs with fewer than 10 words start repeating quickly.")
            }
            Text("Tap a word to add hints and similar words, so the hint and undercover modes work with it.")
        }
    }
}

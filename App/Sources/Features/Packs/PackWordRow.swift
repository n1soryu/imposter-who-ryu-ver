import ImposterKit
import SwiftUI

/// A word in a pack, with a note on how well it works in the hint and undercover modes.
struct PackWordRow: View {
    var card: WordCard
    var edit: () -> Void

    var body: some View {
        Button(action: edit) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.word)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.cardStock)
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(Color.haze)
                }
                Spacer()
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Edits hints and similar words")
    }

    private var detail: String {
        switch (card.hints.count, card.decoys.count) {
        case (0, 0): "No hints or similar words yet"
        case (let hints, 0): hints == 1 ? "1 hint" : "\(hints) hints"
        case (0, let decoys): decoys == 1 ? "1 similar word" : "\(decoys) similar words"
        case (let hints, let decoys):
            "\(hints == 1 ? "1 hint" : "\(hints) hints"), \(decoys == 1 ? "1 similar word" : "\(decoys) similar words")"
        }
    }
}

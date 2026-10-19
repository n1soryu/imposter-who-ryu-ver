import ImposterKit
import SwiftUI

struct PackRow: View {
    var pack: WordCategory
    var open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: 14) {
                Text(pack.symbol)
                    .font(.title2)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.cardStock)
                    Text("^[\(pack.cards.count) word](inflect: true)")
                        .font(.subheadline)
                        .foregroundStyle(Color.haze)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.haze)
                    .accessibilityHidden(true)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

import SwiftUI

/// A tappable tag that's filled with crew ink when it's switched on, and outlined when it's off.
struct SelectableChip: View {
    var title: String
    var symbol: String?
    var isSelected: Bool
    var toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 6) {
                if let symbol {
                    Text(symbol).accessibilityHidden(true)
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 40)
            .padding(.horizontal, 10)
            .foregroundStyle(isSelected ? Color.felt : Color.cardStock)
            .background(isSelected ? Color.crewInk : Color.felt, in: .capsule)
            .overlay {
                Capsule().strokeBorder(isSelected ? Color.clear : Color.haze.opacity(0.5), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.snappy(duration: 0.15), value: isSelected)
    }
}

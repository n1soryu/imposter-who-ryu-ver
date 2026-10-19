import ImposterKit
import SwiftUI

/// A radio-style row. The filled circle means selection isn't shown by colour alone.
struct IntelOptionRow: View {
    var option: GameSettings.ImposterIntel
    var isSelected: Bool
    var select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Color.crewInk : Color.haze)
                    .accessibilityHidden(true)
                RuleLabel(option.title, detail: option.detail)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

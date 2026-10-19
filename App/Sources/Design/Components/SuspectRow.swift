import SwiftUI

/// One player in a `SuspectPicker`. The checkmark means selection isn't shown by colour alone.
struct SuspectRow: View {
    var name: String
    var isSelected: Bool
    var select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack {
                Text(name)
                    .font(.displaySemiBold(22, relativeTo: .title3))
                Spacer()
                Image(systemName: "checkmark")
                    .font(.headline)
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .foregroundStyle(isSelected ? Color.felt : Color.cardStock)
            .background(isSelected ? Color.crewInk : Color.feltRaised, in: .rect(cornerRadius: 18))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

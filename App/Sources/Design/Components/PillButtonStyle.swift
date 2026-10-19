import SwiftUI

/// The full-width capsule button used for every main action.
struct PillButtonStyle: ButtonStyle {
    enum Prominence {
        /// Yellow ink: the one action you most likely want next.
        case primary
        /// Raised felt: everything else.
        case secondary
    }

    var prominence: Prominence

    func makeBody(configuration: Configuration) -> some View {
        PillButton(configuration: configuration, prominence: prominence)
    }

    private struct PillButton: View {
        let configuration: ButtonStyleConfiguration
        let prominence: Prominence
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.displaySemiBold(20))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 30)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .foregroundStyle(prominence == .primary ? Color.felt : Color.cardStock)
                .background(prominence == .primary ? Color.crewInk : Color.feltRaised, in: .capsule)
                .opacity(isEnabled ? 1 : 0.4)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.snappy(duration: 0.15), value: configuration.isPressed)
        }
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    static var pill: PillButtonStyle { PillButtonStyle(prominence: .primary) }
    static var pillSecondary: PillButtonStyle { PillButtonStyle(prominence: .secondary) }
}

#Preview {
    VStack(spacing: 12) {
        Button("New game") {}.buttonStyle(.pill)
        Button("How to play") {}.buttonStyle(.pillSecondary)
        Button("Disabled") {}.buttonStyle(.pill).disabled(true)
    }
    .padding()
    .background(Color.felt)
}

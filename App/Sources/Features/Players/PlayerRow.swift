import SwiftUI

/// A seat at the table. Tapping it renames the player.
struct PlayerRow: View {
    var seat: Int
    var name: String
    var rename: () -> Void

    var body: some View {
        Button(action: rename) {
            HStack(spacing: 16) {
                Text("\(seat)")
                    .font(.displaySemiBold(18, relativeTo: .body))
                    .foregroundStyle(Color.haze)
                    .monospacedDigit()
                    .frame(minWidth: 22, alignment: .trailing)
                Text(name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.cardStock)
                Spacer()
            }
            .contentShape(.rect)
        }
        .accessibilityLabel("Seat \(seat), \(name)")
        .accessibilityHint("Renames this player")
    }
}

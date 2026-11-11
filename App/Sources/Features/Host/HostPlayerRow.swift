import SwiftUI

/// One seat in the lobby or the game: connection dot, name, and an optional remove button.
struct HostPlayerRow: View {
    var name: String
    var isHost: Bool
    var isConnected: Bool
    /// A short status such as "Voted", shown on the right.
    var mark: String?
    var remove: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            ConnectionDot(isConnected: isConnected)
            Text(name)
                .font(.displaySemiBold(20, relativeTo: .body))
                .foregroundStyle(Color.cardStock)
            if isHost {
                Text("You")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.haze)
            }
            Spacer()
            if isConnected == false {
                Text("Offline")
                    .font(.footnote)
                    .foregroundStyle(Color.haze)
            }
            if let mark {
                Text(mark)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.crewInk)
            }
            if let remove {
                Button("Remove \(name)", systemImage: "xmark.circle.fill", action: remove)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Color.haze)
                    .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

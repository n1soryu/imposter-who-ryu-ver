import SwiftUI

/// Yellow when a phone is connected, a hollow haze ring when it isn't.
struct ConnectionDot: View {
    var isConnected: Bool

    var body: some View {
        Circle()
            .fill(isConnected ? Color.crewInk : Color.clear)
            .overlay { Circle().strokeBorder(isConnected ? Color.crewInk : Color.haze, lineWidth: 2) }
            .frame(width: 12, height: 12)
            .accessibilityLabel(isConnected ? "Connected" : "Offline")
    }
}

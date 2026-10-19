import SwiftUI

/// Turns sound effects on or off for this phone.
struct SoundToggleButton: View {
    @Environment(SoundPlayer.self) private var sound

    var body: some View {
        Button(
            sound.isEnabled ? "Turn sound effects off" : "Turn sound effects on",
            systemImage: sound.isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
            action: toggle
        )
        .labelStyle(.iconOnly)
        .font(.title3)
        .foregroundStyle(Color.haze)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(.rect)
    }

    private func toggle() {
        sound.isEnabled.toggle()
    }
}

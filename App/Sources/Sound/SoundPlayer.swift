import AVFoundation
import Observation

/// Plays the sound effects. Uses the ambient audio session, so it follows the silent switch and mixes with music already playing.
@Observable
@MainActor
final class SoundPlayer {
    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Self.enabledKey) }
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var players: [SoundEffect: AVAudioPlayer] = [:]
    private static let enabledKey = "soundEffectsEnabled"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isEnabled = defaults.object(forKey: Self.enabledKey) as? Bool ?? true
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
    }

    func play(_ effect: SoundEffect) {
        guard isEnabled, let player = player(for: effect) else { return }
        player.currentTime = 0
        player.play()
    }

    /// Loads each sound the first time it's needed and keeps it ready for next time.
    private func player(for effect: SoundEffect) -> AVAudioPlayer? {
        if let player = players[effect] { return player }
        guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url)
        else { return nil }
        player.prepareToPlay()
        players[effect] = player
        return player
    }
}

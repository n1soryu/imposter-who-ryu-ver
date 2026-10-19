import Foundation
import ImposterKit
import Observation

/// The house rules from last time, so the group's favourite setup is ready to go.
@Observable
@MainActor
final class RulesStore {
    var rules: HouseRules {
        didSet { save() }
    }

    @ObservationIgnored private let defaults: UserDefaults
    private static let storageKey = "houseRules.v1"

    init(library: WordLibrary, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(HouseRules.self, from: data) {
            rules = saved.pruned(to: library)
        } else {
            rules = .defaults(for: library)
        }
    }

    /// Switches a pack on, for example right after it was created.
    func include(_ id: WordCategory.ID) {
        rules.categoryIDs.insert(id)
    }

    /// Drops categories that no longer exist, for example after a pack is deleted.
    func prune(to library: WordLibrary) {
        let pruned = rules.pruned(to: library)
        if pruned != rules { rules = pruned }
    }

    /// Brings the imposter count into range for the group, for example after someone leaves the table.
    func fit(toPlayers playerCount: Int) {
        let fitted = rules.fitted(toPlayers: playerCount)
        if fitted != rules { rules = fitted }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}

import Foundation
import ImposterKit

/// The saved word history, shared by pass-and-play and host mode so words don't repeat across game nights.
struct WordHistory {
    var defaults: UserDefaults = .standard

    private static let key = "wordHistory.v1"

    func load() -> WordPicker {
        guard let data = defaults.data(forKey: Self.key),
              let picker = try? JSONDecoder().decode(WordPicker.self, from: data)
        else { return WordPicker() }
        return picker
    }

    func save(_ picker: WordPicker) {
        guard let data = try? JSONEncoder().encode(picker) else { return }
        defaults.set(data, forKey: Self.key)
    }
}

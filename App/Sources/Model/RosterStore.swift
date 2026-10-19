import Foundation
import ImposterKit
import Observation

/// The saved group of players, so the same friends don't have to be typed in every game night.
@Observable
@MainActor
final class RosterStore {
    private(set) var roster: Roster {
        didSet { save() }
    }

    @ObservationIgnored private let defaults: UserDefaults
    private static let storageKey = "roster.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(Roster.self, from: data) {
            roster = saved
        } else {
            roster = Roster()
        }
    }

    var players: [Player] { roster.players }

    func add(_ name: String) throws(Roster.NameError) {
        try roster.add(name)
    }

    func rename(_ id: Player.ID, to name: String) throws(Roster.NameError) {
        try roster.rename(id, to: name)
    }

    func remove(atOffsets offsets: IndexSet) {
        roster.remove(atOffsets: offsets)
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        roster.move(fromOffsets: source, toOffset: destination)
    }

    func shuffleSeats() {
        roster.shuffleSeats()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(roster) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}

extension Roster.NameError {
    /// What to tell the person typing, and how to fix it.
    var message: String {
        switch self {
        case .empty:
            "Type a name first."
        case .tooLong(let limit):
            "Names can be up to \(limit) characters."
        case .duplicate(let existing):
            "\(existing) is already playing. Add an initial to tell them apart."
        case .full(let limit):
            "\(limit) players is the most a game can have."
        }
    }
}

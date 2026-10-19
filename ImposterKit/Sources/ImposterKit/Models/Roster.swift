import Foundation

/// The group of players in seating order. Clues go around the circle in this order.
public struct Roster: Hashable, Codable, Sendable {
    public static let maximumPlayers = 15
    public static let maximumNameLength = 20

    public enum NameError: Error, Hashable, Sendable {
        case empty
        case tooLong(limit: Int)
        case duplicate(existing: String)
        case full(limit: Int)
    }

    public private(set) var players: [Player]

    public init(players: [Player] = []) {
        self.players = players
    }

    public var canPlay: Bool {
        players.count >= GameSettings.minimumPlayers
    }

    /// Adds a player to the end of the circle.
    @discardableResult
    public mutating func add(_ name: String) throws(NameError) -> Player {
        guard players.count < Self.maximumPlayers else {
            throw .full(limit: Self.maximumPlayers)
        }
        let player = Player(name: try validated(name, excluding: nil))
        players.append(player)
        return player
    }

    public mutating func rename(_ id: Player.ID, to name: String) throws(NameError) {
        guard let index = players.firstIndex(where: { $0.id == id }) else { return }
        players[index].name = try validated(name, excluding: id)
    }

    public mutating func remove(_ id: Player.ID) {
        players.removeAll { $0.id == id }
    }

    public mutating func remove(atOffsets offsets: IndexSet) {
        for index in offsets.sorted(by: >) where players.indices.contains(index) {
            players.remove(at: index)
        }
    }

    /// Moves players the way `List.onMove` reports it: `destination` is an index in the array before the move.
    public mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        let moving = source.sorted().filter { players.indices.contains($0) }.map { players[$0] }
        let insertion = destination - source.filter { $0 < destination }.count
        remove(atOffsets: source)
        players.insert(contentsOf: moving, at: min(max(insertion, 0), players.count))
    }

    public mutating func shuffleSeats(using generator: inout some RandomNumberGenerator) {
        players.shuffle(using: &generator)
    }

    public mutating func shuffleSeats() {
        var generator = SystemRandomNumberGenerator()
        shuffleSeats(using: &generator)
    }

    /// Trims and collapses spaces, then checks length and uniqueness. Names are compared ignoring case and accents.
    private func validated(_ name: String, excluding id: Player.ID?) throws(NameError) -> String {
        let cleaned = name.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard cleaned.isEmpty == false else { throw .empty }
        guard cleaned.count <= Self.maximumNameLength else { throw .tooLong(limit: Self.maximumNameLength) }

        let key = Self.comparisonKey(cleaned)
        if let existing = players.first(where: { $0.id != id && Self.comparisonKey($0.name) == key }) {
            throw .duplicate(existing: existing.name)
        }
        return cleaned
    }

    private static func comparisonKey(_ name: String) -> String {
        name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}

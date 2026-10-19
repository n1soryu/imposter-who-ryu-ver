import ImposterKit

/// Places for the scoreboard. Players on the same points share a place, like 1, 2, 2, 4.
struct Standings {
    struct Entry {
        var place: Int
        var player: Player
        var points: Int
        var isLeader: Bool
    }

    var entries: [Entry]

    init(session: GameSession) {
        let ranked = session.scoreboard.standings(for: session.players)
        let top = ranked.first?.points ?? 0
        entries = ranked.enumerated().map { index, entry in
            let place = (ranked.firstIndex { $0.points == entry.points } ?? index) + 1
            return Entry(place: place, player: entry.player, points: entry.points, isLeader: top > 0 && entry.points == top)
        }
    }
}

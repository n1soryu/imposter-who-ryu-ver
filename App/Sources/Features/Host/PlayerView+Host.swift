import ImposterKit

extension PlayerView {
    func name(of id: Player.ID) -> String {
        players.first { $0.id == id }?.name ?? "Someone"
    }

    /// The players in the room, as plain `Player` values for the shared pickers.
    var roomPlayers: [Player] {
        players.map { Player(id: $0.id, name: $0.name) }
    }

    /// Names of players the game is waiting on right now whose phones are offline.
    var disconnectedBlockers: [String] {
        let waitingOn: [Player.ID]
        switch phase {
        case .dealing(_, _, _, _, let waitingFor): waitingOn = waitingFor
        case .clues(_, _, _, let current, _): waitingOn = [current]
        case .voting(let voted, _): waitingOn = players.map(\.id).filter { voted.contains($0) == false }
        case .lastChance(let accused, _): waitingOn = [accused]
        case .join, .lobby, .discussion, .finished: waitingOn = []
        }
        return players.filter { $0.isConnected == false && waitingOn.contains($0.id) }.map(\.name)
    }
}

import ImposterKit

/// The facts shown under a round's reveal, worked out once instead of inside the view body.
struct RoundFactsModel {
    var decoys: [(player: Player, decoy: String)]
    var votes: [(player: Player, count: Int)]
    var points: [(player: Player, points: Int)]

    init(round: Round, result: GameSession.RoundResult) {
        decoys = round.players.compactMap { player in
            guard case .undercover(let decoy) = round.role(of: player.id) else { return nil }
            return (player, decoy)
        }

        let counts = result.tally?.counts ?? [:]
        votes = round.players
            .compactMap { player in counts[player.id].map { (player, $0) } }
            .sorted { $0.count > $1.count }

        points = round.players.compactMap { player in
            result.awards[player.id].map { (player, $0) }
        }
    }
}

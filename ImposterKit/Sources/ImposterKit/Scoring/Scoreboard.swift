/// Points awarded at the end of each round.
public struct ScoringRules: Hashable, Codable, Sendable {
    /// Each crew member gets this when the crew catches an imposter.
    public var crewWin: Int
    /// Extra points for a crew member who personally voted for an imposter.
    public var correctVote: Int
    /// Each imposter gets this when the imposters win, whether by surviving or by stealing the win.
    public var imposterWin: Int

    public init(crewWin: Int = 1, correctVote: Int = 1, imposterWin: Int = 2) {
        self.crewWin = crewWin
        self.correctVote = correctVote
        self.imposterWin = imposterWin
    }
}

/// Running totals across the rounds of a session.
public struct Scoreboard: Hashable, Codable, Sendable {
    public var rules: ScoringRules
    public private(set) var points: [Player.ID: Int]
    public private(set) var roundsPlayed: Int

    public init(rules: ScoringRules = ScoringRules()) {
        self.rules = rules
        self.points = [:]
        self.roundsPlayed = 0
    }

    public func points(for playerID: Player.ID) -> Int {
        points[playerID, default: 0]
    }

    /// Points each player earns for a round, without recording them.
    /// - Parameter tally: Secret ballots, if the group used them. A quick group vote has no per-player ballots, so `correctVote` isn't awarded.
    public func awards(for round: Round, outcome: RoundOutcome, tally: VoteTally? = nil) -> [Player.ID: Int] {
        var awards: [Player.ID: Int] = [:]
        let imposters = round.imposterIDs

        switch outcome {
        case .trollRound:
            break
        case .crewWins:
            for player in round.players where imposters.contains(player.id) == false {
                awards[player.id, default: 0] += rules.crewWin
                if let suspect = tally?.ballots[player.id], imposters.contains(suspect) {
                    awards[player.id, default: 0] += rules.correctVote
                }
            }
        case .impostersWin, .imposterStoleWin:
            for id in imposters {
                awards[id, default: 0] += rules.imposterWin
            }
        }
        return awards.filter { $0.value != 0 }
    }

    /// Adds a finished round to the totals and returns what each player earned.
    @discardableResult
    public mutating func record(_ round: Round, outcome: RoundOutcome, tally: VoteTally? = nil) -> [Player.ID: Int] {
        let awards = awards(for: round, outcome: outcome, tally: tally)
        for (id, value) in awards {
            points[id, default: 0] += value
        }
        roundsPlayed += 1
        return awards
    }

    /// Players ranked by points, highest first. Ties keep the given seating order.
    public func standings(for players: [Player]) -> [(player: Player, points: Int)] {
        players.enumerated()
            .sorted { lhs, rhs in
                let (left, right) = (points(for: lhs.element.id), points(for: rhs.element.id))
                return left != right ? left > right : lhs.offset < rhs.offset
            }
            .map { (player: $0.element, points: points(for: $0.element.id)) }
    }
}

/// Counts secret ballots and finds who the group accused.
public struct VoteTally: Hashable, Codable, Sendable {
    /// Each voter's pick: voter → suspect.
    public private(set) var ballots: [Player.ID: Player.ID]

    public init(ballots: [Player.ID: Player.ID] = [:]) {
        self.ballots = ballots
    }

    /// Records or replaces a vote. Players can't vote for themselves.
    @discardableResult
    public mutating func cast(by voter: Player.ID, for suspect: Player.ID) -> Bool {
        guard voter != suspect else { return false }
        ballots[voter] = suspect
        return true
    }

    public func hasVoted(_ voter: Player.ID) -> Bool {
        ballots[voter] != nil
    }

    /// Votes received per suspect.
    public var counts: [Player.ID: Int] {
        ballots.values.reduce(into: [:]) { $0[$1, default: 0] += 1 }
    }

    /// Everyone tied for the most votes.
    public var leaders: [Player.ID] {
        let counts = counts
        guard let top = counts.values.max() else { return [] }
        return counts.filter { $0.value == top }.map(\.key)
    }

    /// The single player with the most votes, or `nil` when no one voted or there's a tie.
    public var accused: Player.ID? {
        let leaders = leaders
        return leaders.count == 1 ? leaders[0] : nil
    }
}

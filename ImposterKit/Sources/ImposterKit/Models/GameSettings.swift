/// House rules for a round.
public struct GameSettings: Hashable, Codable, Sendable {
    /// What an imposter's card shows.
    public enum ImposterIntel: String, Hashable, Codable, Sendable, CaseIterable {
        /// The card just says "Imposter".
        case nothing
        /// The card says "Imposter" plus one related hint word.
        case hint
        /// The card shows a similar decoy word, so the imposter doesn't know they're the imposter.
        case decoy
    }

    public static let minimumPlayers = 3

    public var imposterCount: Int
    public var imposterIntel: ImposterIntel
    /// Chance, from 0 to 1, that a round is a troll round where everyone is secretly an imposter.
    public var trollChance: Double
    /// Whether an imposter may give the first clue, when they have nothing to go on yet.
    public var imposterMayStart: Bool
    /// Whether a caught imposter can steal the win by guessing the word.
    public var lastChanceGuess: Bool
    /// How many times the clues go around the circle before voting.
    public var clueRounds: Int
    /// Seconds per clue turn, or `nil` for no timer.
    public var turnSeconds: Int?
    /// Seconds of discussion before the vote, or `nil` for no timer.
    public var discussionSeconds: Int?

    public init(
        imposterCount: Int = 1,
        imposterIntel: ImposterIntel = .nothing,
        trollChance: Double = 0,
        imposterMayStart: Bool = false,
        lastChanceGuess: Bool = true,
        clueRounds: Int = 2,
        turnSeconds: Int? = nil,
        discussionSeconds: Int? = 120
    ) {
        self.imposterCount = imposterCount
        self.imposterIntel = imposterIntel
        self.trollChance = trollChance
        self.imposterMayStart = imposterMayStart
        self.lastChanceGuess = lastChanceGuess
        self.clueRounds = clueRounds
        self.turnSeconds = turnSeconds
        self.discussionSeconds = discussionSeconds
    }

    /// The most imposters allowed for a group, which keeps the crew a strict majority.
    public static func maximumImposters(forPlayers playerCount: Int) -> Int {
        max(1, (playerCount - 1) / 2)
    }
}

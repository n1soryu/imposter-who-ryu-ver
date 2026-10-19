/// One dealt round: who is what, who speaks first, and how it ends.
public struct Round: Hashable, Codable, Sendable {
    /// Players in seating order. Clues go around in this order.
    public let players: [Player]
    public let card: WordCard
    public let categoryName: String
    public let settings: GameSettings
    public let roles: [Player.ID: Role]
    /// Seating order rotated to start at the first clue-giver.
    public let turnOrder: [Player.ID]
    /// Everyone is secretly an imposter this round.
    public let isTrollRound: Bool

    public init(
        players: [Player],
        card: WordCard,
        categoryName: String,
        settings: GameSettings,
        roles: [Player.ID: Role],
        turnOrder: [Player.ID],
        isTrollRound: Bool
    ) {
        self.players = players
        self.card = card
        self.categoryName = categoryName
        self.settings = settings
        self.roles = roles
        self.turnOrder = turnOrder
        self.isTrollRound = isTrollRound
    }

    public func role(of playerID: Player.ID) -> Role? {
        roles[playerID]
    }

    public func player(_ id: Player.ID) -> Player? {
        players.first { $0.id == id }
    }

    public var imposterIDs: Set<Player.ID> {
        Set(roles.filter { $0.value.isImposter }.keys)
    }

    public func isImposter(_ playerID: Player.ID) -> Bool {
        roles[playerID]?.isImposter ?? false
    }

    /// Whether the accused player now gets a last-chance guess at the word.
    public func offersLastChanceGuess(to accused: Player.ID?) -> Bool {
        guard let accused, isTrollRound == false, settings.lastChanceGuess else { return false }
        return isImposter(accused)
    }

    /// Decides the round from the group's accusation and, if one was offered, the imposter's guess.
    /// - Parameters:
    ///   - accused: The player the group voted out, or `nil` if the vote was tied or nobody was picked.
    ///   - guess: The accused imposter's last-chance guess at the word.
    public func outcome(accused: Player.ID?, guess: String? = nil) -> RoundOutcome {
        if isTrollRound {
            return .trollRound(accused: accused)
        }
        guard let accused, isImposter(accused) else {
            return .impostersWin(accused: accused)
        }
        if offersLastChanceGuess(to: accused), let guess, GuessMatcher.matches(guess, card: card) {
            return .imposterStoleWin(caught: accused, guess: guess)
        }
        return .crewWins(caught: accused)
    }
}

/// How a round ended.
public enum RoundOutcome: Hashable, Codable, Sendable {
    /// The group caught an imposter.
    case crewWins(caught: Player.ID)
    /// The group caught an imposter, but they guessed the word.
    case imposterStoleWin(caught: Player.ID, guess: String)
    /// The group accused a crew member, or couldn't agree on anyone.
    case impostersWin(accused: Player.ID?)
    /// Everyone was an imposter, so the joke is on the whole table.
    case trollRound(accused: Player.ID?)

    public var crewWon: Bool {
        if case .crewWins = self { true } else { false }
    }

    public var impostersWon: Bool {
        switch self {
        case .imposterStoleWin, .impostersWin: true
        case .crewWins, .trollRound: false
        }
    }
}

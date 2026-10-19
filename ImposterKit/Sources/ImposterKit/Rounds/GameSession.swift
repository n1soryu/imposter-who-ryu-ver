/// Why a game couldn't start or move to the next round.
public enum GameError: Error, Hashable, Sendable {
    case deal(DealError)
    /// No words match the chosen categories and difficulties.
    case noWords
}

/// A game night: rounds played one after another by the same group, with a running scoreboard.
///
/// Each round moves through the phases in order. The mutating methods only act in the phase they belong to and do nothing otherwise, so a double tap can never skip a step.
public struct GameSession: Hashable, Sendable {
    public enum Phase: Hashable, Sendable {
        /// The phone goes around and `seat` (an index into the round's players) looks at their card.
        case dealing(seat: Int)
        /// `turn` is an index into the round's turn order. `lap` counts from 1.
        case clues(lap: Int, turn: Int)
        case discussion
        /// Secret ballots, collected by passing the phone.
        case voting(VoteTally)
        /// The accused imposter gets one guess at the word.
        case lastChance(accused: Player.ID)
        case finished(RoundResult)
    }

    public struct RoundResult: Hashable, Sendable {
        public let outcome: RoundOutcome
        /// Points earned this round.
        public let awards: [Player.ID: Int]
        public let tally: VoteTally?
    }

    public private(set) var players: [Player]
    public private(set) var rules: HouseRules
    public private(set) var round: Round
    public private(set) var categorySymbol: String
    public private(set) var phase: Phase
    public private(set) var roundNumber: Int
    public private(set) var scoreboard: Scoreboard
    /// Word history, so words don't repeat. Save it when the game ends.
    public private(set) var picker: WordPicker
    private var pendingTally: VoteTally?

    public init(
        players: [Player],
        rules: HouseRules,
        library: WordLibrary,
        picker: WordPicker = WordPicker(),
        scoring: ScoringRules = ScoringRules(),
        using generator: inout some RandomNumberGenerator
    ) throws(GameError) {
        var picker = picker
        let rules = rules.fitted(toPlayers: players.count)
        let (round, symbol) = try Self.deal(players: players, rules: rules, library: library, picker: &picker, using: &generator)
        self.players = players
        self.rules = rules
        self.round = round
        self.categorySymbol = symbol
        self.phase = .dealing(seat: 0)
        self.roundNumber = 1
        self.scoreboard = Scoreboard(rules: scoring)
        self.picker = picker
    }

    public init(players: [Player], rules: HouseRules, library: WordLibrary, picker: WordPicker = WordPicker()) throws(GameError) {
        var generator = SystemRandomNumberGenerator()
        try self.init(players: players, rules: rules, library: library, picker: picker, using: &generator)
    }

    // MARK: Dealing

    /// The player who should be holding the phone during the deal.
    public var currentDealSeat: Player? {
        guard case .dealing(let seat) = phase else { return nil }
        return round.players[seat]
    }

    /// The player holding the phone has seen their card. Moves to the next seat, or to clues after the last one.
    public mutating func cardSeen() {
        guard case .dealing(let seat) = phase else { return }
        let next = seat + 1
        phase = next < round.players.count ? .dealing(seat: next) : .clues(lap: 1, turn: 0)
    }

    // MARK: Clues

    /// Whose turn it is to give a clue.
    public var currentCluegiver: Player? {
        guard case .clues(_, let turn) = phase else { return nil }
        return round.player(round.turnOrder[turn])
    }

    /// The current player gave their clue. After the last turn of the last lap, discussion starts.
    public mutating func clueGiven() {
        guard case .clues(let lap, let turn) = phase else { return }
        if turn + 1 < round.turnOrder.count {
            phase = .clues(lap: lap, turn: turn + 1)
        } else if lap < rules.settings.clueRounds {
            phase = .clues(lap: lap + 1, turn: 0)
        } else {
            phase = .discussion
        }
    }

    /// Skips the remaining clues and goes to discussion.
    public mutating func endClues() {
        guard case .clues = phase else { return }
        phase = .discussion
    }

    // MARK: Voting

    /// Starts passing the phone for secret ballots.
    public mutating func startVoting() {
        switch phase {
        case .clues, .discussion: phase = .voting(VoteTally())
        default: return
        }
    }

    /// The next player in seating order who hasn't voted yet.
    public var nextVoter: Player? {
        guard case .voting(let tally) = phase else { return nil }
        return round.players.first { tally.hasVoted($0.id) == false }
    }

    /// Records the next voter's pick. Ignored if it isn't that player's turn or they pick themselves.
    public mutating func castVote(by voter: Player.ID, for suspect: Player.ID) {
        guard case .voting(var tally) = phase, nextVoter?.id == voter else { return }
        tally.cast(by: voter, for: suspect)
        phase = .voting(tally)
    }

    /// Ends secret voting and accuses whoever got the most votes. A tie accuses nobody.
    public mutating func finishVoting() {
        guard case .voting(let tally) = phase else { return }
        accuse(tally.accused, tally: tally)
    }

    /// The group agreed out loud on who to accuse, with no secret ballots. `nil` means they couldn't agree.
    public mutating func accuse(_ accused: Player.ID?) {
        switch phase {
        case .clues, .discussion, .voting: accuse(accused, tally: nil)
        default: return
        }
    }

    private mutating func accuse(_ accused: Player.ID?, tally: VoteTally?) {
        pendingTally = tally
        if let accused, round.offersLastChanceGuess(to: accused) {
            phase = .lastChance(accused: accused)
        } else {
            finish(round.outcome(accused: accused))
        }
    }

    // MARK: Last chance

    /// The caught imposter's guess at the word. `nil` means they gave up.
    public mutating func submitGuess(_ guess: String?) {
        guard case .lastChance(let accused) = phase else { return }
        finish(round.outcome(accused: accused, guess: guess))
    }

    private mutating func finish(_ outcome: RoundOutcome) {
        let awards = scoreboard.record(round, outcome: outcome, tally: pendingTally)
        phase = .finished(RoundResult(outcome: outcome, awards: awards, tally: pendingTally))
        pendingTally = nil
    }

    // MARK: Next round

    /// Deals a fresh round to the same group, keeping the scores. Only allowed once the current round is finished.
    public mutating func nextRound(library: WordLibrary, using generator: inout some RandomNumberGenerator) throws(GameError) {
        guard case .finished = phase else { return }
        let (round, symbol) = try Self.deal(players: players, rules: rules, library: library, picker: &picker, using: &generator)
        self.round = round
        self.categorySymbol = symbol
        phase = .dealing(seat: 0)
        roundNumber += 1
    }

    public mutating func nextRound(library: WordLibrary) throws(GameError) {
        var generator = SystemRandomNumberGenerator()
        try nextRound(library: library, using: &generator)
    }

    private static func deal(
        players: [Player],
        rules: HouseRules,
        library: WordLibrary,
        picker: inout WordPicker,
        using generator: inout some RandomNumberGenerator
    ) throws(GameError) -> (Round, symbol: String) {
        guard let draw = picker.draw(from: rules.categories(in: library), difficulties: rules.difficulties, using: &generator) else {
            throw .noWords
        }
        do {
            let round = try RoundDealer.deal(
                players: players,
                card: draw.card,
                categoryName: draw.categoryName,
                settings: rules.settings,
                using: &generator
            )
            return (round, draw.categorySymbol)
        } catch {
            throw .deal(error)
        }
    }
}

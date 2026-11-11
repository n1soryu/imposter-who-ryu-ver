import Foundation

/// Someone at the table: a player, the secret token their phone keeps, and whether that phone is online.
public struct Seat: Hashable, Sendable {
    public var player: Player
    public var token: String
    public let isHost: Bool
    public var isConnected: Bool
}

/// A hosted game: the seats, the game itself and the host-only bookkeeping. Pure logic, no networking.
///
/// Game actions do nothing when they don't fit the phase or the caller, and say so by returning `false`. `version` goes up only when something really changed.
public struct HostSession: Hashable, Sendable {
    /// How many times each player may look at their card again during a round.
    public static let peeksPerRound = 3

    /// Everyone at the table in seating order. The host is always first.
    public private(set) var seats: [Seat]
    /// `nil` in the lobby.
    public private(set) var game: GameSession?
    /// Who has marked their card seen during the deal.
    public private(set) var seen: Set<Player.ID>
    public private(set) var peeksUsed: [Player.ID: Int]
    /// Goes up on every real change.
    public private(set) var version: Int
    private var timerStart: Date?

    /// Seats the host. The host is always connected.
    public init(hostName: String, using generator: inout some RandomNumberGenerator) throws(HostError) {
        var roster = Roster()
        let player = try Self.add(hostName, to: &roster)
        self.seats = [Seat(player: player, token: Self.makeToken(using: &generator), isHost: true, isConnected: true)]
        self.game = nil
        self.seen = []
        self.peeksUsed = [:]
        self.version = 0
    }

    public init(hostName: String) throws(HostError) {
        var generator = SystemRandomNumberGenerator()
        try self.init(hostName: hostName, using: &generator)
    }

    // MARK: Lookup

    public var host: Seat { seats[0] }
    public var players: [Player] { seats.map(\.player) }

    public func seat(for id: Player.ID) -> Seat? {
        seats.first { $0.player.id == id }
    }

    public func seat(forToken token: String) -> Seat? {
        seats.first { $0.token == token }
    }

    /// Joining is open in the lobby and on the finished screen, while there is room.
    public var canJoin: Bool {
        guard seats.count < Roster.maximumPlayers else { return false }
        guard let game else { return true }
        if case .finished = game.phase { return true }
        return false
    }

    public func peeksLeft(for id: Player.ID) -> Int {
        max(0, Self.peeksPerRound - peeksUsed[id, default: 0])
    }

    // MARK: Joining and connections

    /// Seats a new player. Late joiners play from the next round.
    @discardableResult
    public mutating func join(name: String, using generator: inout some RandomNumberGenerator) throws(HostError) -> Seat {
        guard isBetweenRounds else { throw .roundInProgress }
        var roster = Roster(players: players)
        let player = try Self.add(name, to: &roster)
        let seat = Seat(player: player, token: newToken(using: &generator), isHost: false, isConnected: true)
        seats.append(seat)
        version += 1
        return seat
    }

    @discardableResult
    public mutating func join(name: String) throws(HostError) -> Seat {
        var generator = SystemRandomNumberGenerator()
        return try join(name: name, using: &generator)
    }

    /// The seat for a known token, for a phone that slept or reloaded. Marks it connected.
    @discardableResult
    public mutating func resume(token: String) throws(HostError) -> Seat {
        guard let index = seats.firstIndex(where: { $0.token == token }) else { throw .unknownToken }
        if seats[index].isConnected == false {
            seats[index].isConnected = true
            version += 1
        }
        return seats[index]
    }

    /// Takes over a seat whose phone is disconnected, for a browser that lost its token. The old token stops working.
    @discardableResult
    public mutating func claim(playerID: Player.ID, using generator: inout some RandomNumberGenerator) throws(HostError) -> Seat {
        guard let index = seats.firstIndex(where: { $0.player.id == playerID }) else { throw .notAllowed }
        guard seats[index].isConnected == false else { throw .seatTaken }
        seats[index].token = newToken(using: &generator)
        seats[index].isConnected = true
        version += 1
        return seats[index]
    }

    @discardableResult
    public mutating func claim(playerID: Player.ID) throws(HostError) -> Seat {
        var generator = SystemRandomNumberGenerator()
        return try claim(playerID: playerID, using: &generator)
    }

    /// Called as sockets open and close. The host stays connected.
    @discardableResult
    public mutating func setConnected(_ connected: Bool, for id: Player.ID) -> Bool {
        guard let index = seats.firstIndex(where: { $0.player.id == id }),
              seats[index].isHost == false,
              seats[index].isConnected != connected
        else { return false }
        seats[index].isConnected = connected
        version += 1
        return true
    }

    /// Removes a seat and revokes its token. Only in the lobby or on the finished screen, and never the host.
    @discardableResult
    public mutating func kick(_ id: Player.ID) -> Bool {
        guard isBetweenRounds, let index = seats.firstIndex(where: { $0.player.id == id }), seats[index].isHost == false else { return false }
        seats.remove(at: index)
        peeksUsed[id] = nil
        seen.remove(id)
        version += 1
        return true
    }

    /// A player leaves by themselves. Lobby only.
    @discardableResult
    public mutating func leave(_ id: Player.ID) -> Bool {
        guard game == nil, let index = seats.firstIndex(where: { $0.player.id == id }), seats[index].isHost == false else { return false }
        seats.remove(at: index)
        version += 1
        return true
    }

    // MARK: Game actions

    /// Deals round 1 to all seats. Lobby only.
    public mutating func start(
        rules: HouseRules,
        library: WordLibrary,
        picker: WordPicker = WordPicker(),
        now: Date = Date(),
        using generator: inout some RandomNumberGenerator
    ) throws(GameError) {
        guard game == nil else { return }
        let before = self
        game = try GameSession(players: players, rules: rules, library: library, picker: picker, using: &generator)
        resetRoundState()
        conclude(before, now: now)
    }

    public mutating func start(rules: HouseRules, library: WordLibrary, picker: WordPicker = WordPicker(), now: Date = Date()) throws(GameError) {
        var generator = SystemRandomNumberGenerator()
        try start(rules: rules, library: library, picker: picker, now: now, using: &generator)
    }

    /// The player has seen their card. When everyone has, clues start.
    @discardableResult
    public mutating func cardSeen(by id: Player.ID, now: Date = Date()) -> Bool {
        guard var game, case .dealing = game.phase, game.round.player(id) != nil, seen.contains(id) == false else { return false }
        let before = self
        seen.insert(id)
        if game.round.players.allSatisfy({ seen.contains($0.id) }) {
            game.finishDeal()
        }
        self.game = game
        return conclude(before, now: now)
    }

    /// The current clue-giver, or the host, says the clue is done.
    @discardableResult
    public mutating func clueDone(by id: Player.ID, now: Date = Date()) -> Bool {
        guard let current = game?.currentCluegiver, id == current.id || id == host.player.id else { return false }
        return update(now: now) { $0.clueGiven() }
    }

    @discardableResult
    public mutating func endClues(now: Date = Date()) -> Bool {
        update(now: now) { $0.endClues() }
    }

    @discardableResult
    public mutating func startVoting(now: Date = Date()) -> Bool {
        update(now: now) { $0.startVoting() }
    }

    /// The quick group vote. `nil` means nobody agreed.
    @discardableResult
    public mutating func quickAccuse(_ accused: Player.ID?, now: Date = Date()) -> Bool {
        update(now: now) { $0.accuse(accused) }
    }

    /// A secret ballot. When every player has voted, voting finishes.
    @discardableResult
    public mutating func vote(by voter: Player.ID, for suspect: Player.ID, now: Date = Date()) -> Bool {
        update(now: now) { game in
            game.castBallot(by: voter, for: suspect)
            if case .voting(let tally) = game.phase, game.round.players.allSatisfy({ tally.hasVoted($0.id) }) {
                game.finishVoting()
            }
        }
    }

    /// Ends voting early with the ballots in so far.
    @discardableResult
    public mutating func revealVotes(now: Date = Date()) -> Bool {
        update(now: now) { $0.finishVoting() }
    }

    /// The accused imposter's last guess. `nil` gives up.
    @discardableResult
    public mutating func guess(by id: Player.ID, text: String?, now: Date = Date()) -> Bool {
        guard case .lastChance(let accused)? = game?.phase, accused == id else { return false }
        return update(now: now) { $0.submitGuess(text) }
    }

    /// Looks at the player's card again. Uses one of their peeks.
    public mutating func peek(by id: Player.ID) throws(HostError) -> CardFace {
        guard let game, let role = game.round.role(of: id), Self.allowsPeek(game.phase) else { throw .notAllowed }
        guard peeksLeft(for: id) > 0 else { throw .noPeeksLeft }
        peeksUsed[id, default: 0] += 1
        version += 1
        return role.cardFace
    }

    /// Deals the next round to the current seats, including late joiners. Finished rounds only.
    public mutating func nextRound(library: WordLibrary, now: Date = Date(), using generator: inout some RandomNumberGenerator) throws(GameError) {
        guard var game, case .finished = game.phase else { return }
        let before = self
        try game.nextRound(players: players, library: library, using: &generator)
        self.game = game
        resetRoundState()
        conclude(before, now: now)
    }

    public mutating func nextRound(library: WordLibrary, now: Date = Date()) throws(GameError) {
        var generator = SystemRandomNumberGenerator()
        try nextRound(library: library, now: now, using: &generator)
    }

    /// Back to the lobby with everyone still seated.
    @discardableResult
    public mutating func endGame() -> Bool {
        guard game != nil else { return false }
        game = nil
        resetRoundState()
        version += 1
        return true
    }

    // MARK: Views

    /// What this player may see. A player who isn't seated gets the join screen.
    public func view(for id: Player.ID, now: Date = Date()) -> PlayerView {
        guard let seat = seat(for: id) else { return joinView(now: now) }
        return PlayerView(
            version: version,
            you: PlayerView.Identity(id: id, name: seat.player.name),
            players: participants,
            scores: scores,
            roundNumber: game?.roundNumber ?? 0,
            peeksLeft: peeksLeft(for: id),
            phase: phase(for: id, now: now)
        )
    }

    /// What a phone sees before it has joined.
    public func joinView(now: Date = Date()) -> PlayerView {
        PlayerView(
            version: version,
            you: nil,
            players: participants,
            scores: scores,
            roundNumber: game?.roundNumber ?? 0,
            peeksLeft: 0,
            phase: .join(canJoin: canJoin, claimable: seats.filter { $0.isConnected == false }.map(\.player.id))
        )
    }

    // MARK: Internals

    private var isBetweenRounds: Bool {
        guard let game else { return true }
        if case .finished = game.phase { return true }
        return false
    }

    private static func allowsPeek(_ phase: GameSession.Phase) -> Bool {
        switch phase {
        case .clues, .discussion, .voting, .lastChance: true
        case .dealing, .finished: false
        }
    }

    private static func add(_ name: String, to roster: inout Roster) throws(HostError) -> Player {
        do throws(Roster.NameError) {
            return try roster.add(name)
        } catch {
            throw HostError(error)
        }
    }

    private static func makeToken(using generator: inout some RandomNumberGenerator) -> String {
        let high = String(generator.next(), radix: 16)
        let low = String(generator.next(), radix: 16)
        return String(repeating: "0", count: 16 - high.count) + high + String(repeating: "0", count: 16 - low.count) + low
    }

    private func newToken(using generator: inout some RandomNumberGenerator) -> String {
        var token = Self.makeToken(using: &generator)
        while seats.contains(where: { $0.token == token }) {
            token = Self.makeToken(using: &generator)
        }
        return token
    }

    private mutating func resetRoundState() {
        seen = []
        peeksUsed = [:]
    }

    /// Runs a game change and reports whether anything happened.
    private mutating func update(now: Date, _ change: (inout GameSession) -> Void) -> Bool {
        guard var game else { return false }
        let before = self
        change(&game)
        self.game = game
        return conclude(before, now: now)
    }

    /// Bumps the version if the session differs from `before`, and restarts the timer when the clue turn or discussion changed.
    @discardableResult
    private mutating func conclude(_ before: HostSession, now: Date) -> Bool {
        guard self != before else { return false }
        if timerKey(game) != timerKey(before.game) {
            timerStart = now
        }
        version += 1
        return true
    }

    private enum TimerKey: Hashable {
        case clue(lap: Int, turn: Int)
        case discussion
    }

    private func timerKey(_ game: GameSession?) -> TimerKey? {
        switch game?.phase {
        case .clues(let lap, let turn): .clue(lap: lap, turn: turn)
        case .discussion: .discussion
        default: nil
        }
    }

    private func secondsLeft(total: Int?, now: Date) -> Int? {
        guard let total else { return nil }
        let elapsed = timerStart.map { Int(now.timeIntervalSince($0)) } ?? 0
        return max(0, total - max(0, elapsed))
    }

    private var participants: [PlayerView.Participant] {
        seats.map { PlayerView.Participant(id: $0.player.id, name: $0.player.name, isHost: $0.isHost, isConnected: $0.isConnected) }
    }

    private var scores: [PlayerView.Score] {
        let board = game?.scoreboard ?? Scoreboard()
        return board.standings(for: players).map { PlayerView.Score(id: $0.player.id, points: $0.points) }
    }

    private func phase(for id: Player.ID, now: Date) -> PlayerView.Phase {
        guard let game else { return .lobby(canStart: seats.count >= GameSettings.minimumPlayers) }
        let round = game.round
        let settings = game.rules.settings

        switch game.phase {
        case .dealing:
            let hasSeen = seen.contains(id)
            let face = hasSeen ? nil : round.role(of: id)?.cardFace
            return .dealing(
                categoryName: round.categoryName,
                categorySymbol: game.categorySymbol,
                face: face,
                seen: hasSeen,
                waitingFor: round.players.map(\.id).filter { seen.contains($0) == false }
            )
        case .clues(let lap, let turn):
            return .clues(
                lap: lap,
                laps: settings.clueRounds,
                turnOrder: round.turnOrder,
                current: round.turnOrder[turn],
                secondsLeft: secondsLeft(total: settings.turnSeconds, now: now)
            )
        case .discussion:
            return .discussion(secondsLeft: secondsLeft(total: settings.discussionSeconds, now: now))
        case .voting(let tally):
            return .voting(voted: round.players.map(\.id).filter(tally.hasVoted), youVoted: tally.hasVoted(id))
        case .lastChance(let accused):
            return .lastChance(accused: accused, youAreAccused: accused == id)
        case .finished(let result):
            return .finished(finished(result, round: round))
        }
    }

    private func finished(_ result: GameSession.RoundResult, round: Round) -> PlayerView.Finished {
        let order = round.players.map(\.id)
        let outcome: PlayerView.Outcome
        switch result.outcome {
        case .crewWins(let caught): outcome = .init(kind: .crewWins, playerID: caught, guess: nil)
        case .imposterStoleWin(let caught, let guess): outcome = .init(kind: .imposterStoleWin, playerID: caught, guess: guess)
        case .impostersWin(let accused): outcome = .init(kind: .impostersWin, playerID: accused, guess: nil)
        case .trollRound(let accused): outcome = .init(kind: .trollRound, playerID: accused, guess: nil)
        }
        return PlayerView.Finished(
            outcome: outcome,
            word: round.card.word,
            imposters: order.filter(round.isImposter),
            troll: round.isTrollRound,
            awards: order.compactMap { id in result.awards[id].map { PlayerView.Award(id: id, points: $0) } },
            ballots: result.tally.map { tally in
                order.compactMap { voter in tally.ballots[voter].map { PlayerView.Ballot(voter: voter, suspect: $0) } }
            }
        )
    }
}

import Foundation

/// Everything one phone may see. Never holds the round, roles, the secret word, decoy or hint, imposters or ballots before the round is finished.
public struct PlayerView: Hashable, Codable, Sendable {
    public struct Identity: Hashable, Codable, Sendable {
        public let id: Player.ID
        public let name: String
    }

    public struct Participant: Hashable, Codable, Sendable {
        public let id: Player.ID
        public let name: String
        public let isHost: Bool
        public let isConnected: Bool

        private enum CodingKeys: String, CodingKey {
            case id, name, isHost
            case isConnected = "connected"
        }
    }

    public struct Score: Hashable, Codable, Sendable {
        public let id: Player.ID
        public let points: Int
    }

    public struct Award: Hashable, Codable, Sendable {
        public let id: Player.ID
        public let points: Int
    }

    public struct Ballot: Hashable, Codable, Sendable {
        public let voter: Player.ID
        public let suspect: Player.ID
    }

    public struct Outcome: Hashable, Codable, Sendable {
        public enum Kind: String, Hashable, Codable, Sendable {
            case crewWins, imposterStoleWin, impostersWin, trollRound
        }

        public let kind: Kind
        /// Who was caught or accused, if anyone.
        public let playerID: Player.ID?
        /// The imposter's winning guess.
        public let guess: String?

        private enum CodingKeys: String, CodingKey {
            case kind, guess
            case playerID = "playerId"
        }

        init(kind: Kind, playerID: Player.ID?, guess: String?) {
            self.kind = kind
            self.playerID = playerID
            self.guess = guess
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            kind = try container.decode(Kind.self, forKey: .kind)
            playerID = try container.decodeIfPresent(Player.ID.self, forKey: .playerID)
            guess = try container.decodeIfPresent(String.self, forKey: .guess)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(kind, forKey: .kind)
            try container.encode(playerID, forKey: .playerID)
            try container.encode(guess, forKey: .guess)
        }
    }

    /// The reveal. Only sent once the round is over.
    public struct Finished: Hashable, Sendable {
        public let outcome: Outcome
        public let word: String
        public let imposters: [Player.ID]
        public let troll: Bool
        public let awards: [Award]
        /// `nil` after a quick group vote.
        public let ballots: [Ballot]?
    }

    public enum Phase: Hashable, Sendable {
        case join(canJoin: Bool, claimable: [Player.ID])
        case lobby(canStart: Bool)
        /// `face` is only set while this player hasn't marked their card seen.
        case dealing(categoryName: String, categorySymbol: String, face: CardFace?, seen: Bool, waitingFor: [Player.ID])
        case clues(lap: Int, laps: Int, turnOrder: [Player.ID], current: Player.ID, secondsLeft: Int?)
        case discussion(secondsLeft: Int?)
        case voting(voted: [Player.ID], youVoted: Bool)
        case lastChance(accused: Player.ID, youAreAccused: Bool)
        case finished(Finished)
    }

    public let version: Int
    /// `nil` before the phone has joined.
    public let you: Identity?
    public let players: [Participant]
    /// In standings order.
    public let scores: [Score]
    public let roundNumber: Int
    public let peeksLeft: Int
    public let phase: Phase
}

// MARK: - JSON

/// A card face as it travels: `{"kind":"word","word":"…"}` or `{"kind":"imposter","hint":"…"|null}`.
struct CardFaceJSON: Codable {
    let face: CardFace

    private enum CodingKeys: String, CodingKey {
        case kind, word, hint
    }

    init(_ face: CardFace) {
        self.face = face
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(String.self, forKey: .kind) {
        case "word":
            face = .word(try container.decode(String.self, forKey: .word))
        case "imposter":
            face = .imposter(hint: try container.decodeIfPresent(String.self, forKey: .hint))
        case let kind:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown face kind \(kind)")
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch face {
        case .word(let word):
            try container.encode("word", forKey: .kind)
            try container.encode(word, forKey: .word)
        case .imposter(let hint):
            try container.encode("imposter", forKey: .kind)
            try container.encode(hint, forKey: .hint)
        }
    }
}

extension PlayerView.Finished: Codable {
    private enum CodingKeys: String, CodingKey {
        case outcome, word, imposters, troll, awards, ballots
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        outcome = try container.decode(PlayerView.Outcome.self, forKey: .outcome)
        word = try container.decode(String.self, forKey: .word)
        imposters = try container.decode([Player.ID].self, forKey: .imposters)
        troll = try container.decode(Bool.self, forKey: .troll)
        awards = try container.decode([PlayerView.Award].self, forKey: .awards)
        ballots = try container.decodeIfPresent([PlayerView.Ballot].self, forKey: .ballots)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(outcome, forKey: .outcome)
        try container.encode(word, forKey: .word)
        try container.encode(imposters, forKey: .imposters)
        try container.encode(troll, forKey: .troll)
        try container.encode(awards, forKey: .awards)
        try container.encode(ballots, forKey: .ballots)
    }
}

extension PlayerView.Phase: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case canJoin, claimable
        case canStart
        case categoryName, categorySymbol, face, seen, waitingFor
        case lap, laps, turnOrder, current, secondsLeft
        case voted, youVoted
        case accused, youAreAccused
        case outcome, word, imposters, troll, awards, ballots
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(String.self, forKey: .name) {
        case "join":
            self = .join(canJoin: try container.decode(Bool.self, forKey: .canJoin), claimable: try container.decode([Player.ID].self, forKey: .claimable))
        case "lobby":
            self = .lobby(canStart: try container.decode(Bool.self, forKey: .canStart))
        case "dealing":
            self = .dealing(
                categoryName: try container.decode(String.self, forKey: .categoryName),
                categorySymbol: try container.decode(String.self, forKey: .categorySymbol),
                face: try container.decodeIfPresent(CardFaceJSON.self, forKey: .face)?.face,
                seen: try container.decode(Bool.self, forKey: .seen),
                waitingFor: try container.decode([Player.ID].self, forKey: .waitingFor)
            )
        case "clues":
            self = .clues(
                lap: try container.decode(Int.self, forKey: .lap),
                laps: try container.decode(Int.self, forKey: .laps),
                turnOrder: try container.decode([Player.ID].self, forKey: .turnOrder),
                current: try container.decode(Player.ID.self, forKey: .current),
                secondsLeft: try container.decodeIfPresent(Int.self, forKey: .secondsLeft)
            )
        case "discussion":
            self = .discussion(secondsLeft: try container.decodeIfPresent(Int.self, forKey: .secondsLeft))
        case "voting":
            self = .voting(voted: try container.decode([Player.ID].self, forKey: .voted), youVoted: try container.decode(Bool.self, forKey: .youVoted))
        case "lastChance":
            self = .lastChance(accused: try container.decode(Player.ID.self, forKey: .accused), youAreAccused: try container.decode(Bool.self, forKey: .youAreAccused))
        case "finished":
            self = .finished(try PlayerView.Finished(from: decoder))
        case let name:
            throw DecodingError.dataCorruptedError(forKey: .name, in: container, debugDescription: "Unknown phase \(name)")
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .join(let canJoin, let claimable):
            try container.encode("join", forKey: .name)
            try container.encode(canJoin, forKey: .canJoin)
            try container.encode(claimable, forKey: .claimable)
        case .lobby(let canStart):
            try container.encode("lobby", forKey: .name)
            try container.encode(canStart, forKey: .canStart)
        case .dealing(let categoryName, let categorySymbol, let face, let seen, let waitingFor):
            try container.encode("dealing", forKey: .name)
            try container.encode(categoryName, forKey: .categoryName)
            try container.encode(categorySymbol, forKey: .categorySymbol)
            try container.encodeIfPresent(face.map(CardFaceJSON.init), forKey: .face)
            try container.encode(seen, forKey: .seen)
            try container.encode(waitingFor, forKey: .waitingFor)
        case .clues(let lap, let laps, let turnOrder, let current, let secondsLeft):
            try container.encode("clues", forKey: .name)
            try container.encode(lap, forKey: .lap)
            try container.encode(laps, forKey: .laps)
            try container.encode(turnOrder, forKey: .turnOrder)
            try container.encode(current, forKey: .current)
            try container.encode(secondsLeft, forKey: .secondsLeft)
        case .discussion(let secondsLeft):
            try container.encode("discussion", forKey: .name)
            try container.encode(secondsLeft, forKey: .secondsLeft)
        case .voting(let voted, let youVoted):
            try container.encode("voting", forKey: .name)
            try container.encode(voted, forKey: .voted)
            try container.encode(youVoted, forKey: .youVoted)
        case .lastChance(let accused, let youAreAccused):
            try container.encode("lastChance", forKey: .name)
            try container.encode(accused, forKey: .accused)
            try container.encode(youAreAccused, forKey: .youAreAccused)
        case .finished(let finished):
            try container.encode("finished", forKey: .name)
            try container.encode(finished.outcome, forKey: .outcome)
            try container.encode(finished.word, forKey: .word)
            try container.encode(finished.imposters, forKey: .imposters)
            try container.encode(finished.troll, forKey: .troll)
            try container.encode(finished.awards, forKey: .awards)
            try container.encode(finished.ballots, forKey: .ballots)
        }
    }
}

extension PlayerView {
    private enum CodingKeys: String, CodingKey {
        case version, you, players, scores, roundNumber, peeksLeft, phase
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        you = try container.decodeIfPresent(Identity.self, forKey: .you)
        players = try container.decode([Participant].self, forKey: .players)
        scores = try container.decode([Score].self, forKey: .scores)
        roundNumber = try container.decode(Int.self, forKey: .roundNumber)
        peeksLeft = try container.decode(Int.self, forKey: .peeksLeft)
        phase = try container.decode(Phase.self, forKey: .phase)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(you, forKey: .you)
        try container.encode(players, forKey: .players)
        try container.encode(scores, forKey: .scores)
        try container.encode(roundNumber, forKey: .roundNumber)
        try container.encode(peeksLeft, forKey: .peeksLeft)
        try container.encode(phase, forKey: .phase)
    }
}

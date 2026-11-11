import Foundation

/// A host command sent from a dev browser tab. Only the Mac dev server accepts these.
public enum HostCommand: Hashable, Sendable {
    case start
    case endClues
    case startVoting
    /// `nil` means the group couldn't agree.
    case quickAccuse(Player.ID?)
    case revealVotes
    case nextRound
    case endGame
    case kick(Player.ID)
}

/// Phone to host. Types the host doesn't know decode as `.unknown` so they can be ignored.
public enum ClientMessage: Hashable, Sendable, Decodable {
    case resume(token: String)
    case join(name: String)
    case claim(playerID: Player.ID)
    case cardSeen
    case clueDone
    case vote(suspect: Player.ID)
    /// `nil` gives up.
    case guess(text: String?)
    case peek
    case leave
    case host(HostCommand)
    case unknown(type: String)

    private enum CodingKeys: String, CodingKey {
        case type, token, name, playerId, suspect, text, command
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "resume": self = .resume(token: try container.decode(String.self, forKey: .token))
        case "join": self = .join(name: try container.decode(String.self, forKey: .name))
        case "claim": self = .claim(playerID: try container.decode(Player.ID.self, forKey: .playerId))
        case "cardSeen": self = .cardSeen
        case "clueDone": self = .clueDone
        case "vote": self = .vote(suspect: try container.decode(Player.ID.self, forKey: .suspect))
        case "guess": self = .guess(text: try container.decodeIfPresent(String.self, forKey: .text))
        case "peek": self = .peek
        case "leave": self = .leave
        case "host":
            switch try container.decode(String.self, forKey: .command) {
            case "start": self = .host(.start)
            case "endClues": self = .host(.endClues)
            case "startVoting": self = .host(.startVoting)
            case "quickAccuse": self = .host(.quickAccuse(try container.decodeIfPresent(Player.ID.self, forKey: .playerId)))
            case "revealVotes": self = .host(.revealVotes)
            case "nextRound": self = .host(.nextRound)
            case "endGame": self = .host(.endGame)
            case "kick": self = .host(.kick(try container.decode(Player.ID.self, forKey: .playerId)))
            default: self = .unknown(type: type)
            }
        default: self = .unknown(type: type)
        }
    }
}

/// Host to phone.
public enum ServerMessage: Hashable, Sendable, Encodable {
    case welcome(playerID: Player.ID, token: String)
    case state(PlayerView)
    case peek(face: CardFace, peeksLeft: Int)
    case error(HostError)
    case kicked

    private enum CodingKeys: String, CodingKey {
        case type, playerId, token, view, face, peeksLeft, code, message
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .welcome(let playerID, let token):
            try container.encode("welcome", forKey: .type)
            try container.encode(playerID, forKey: .playerId)
            try container.encode(token, forKey: .token)
        case .state(let view):
            try container.encode("state", forKey: .type)
            try container.encode(view, forKey: .view)
        case .peek(let face, let peeksLeft):
            try container.encode("peek", forKey: .type)
            try container.encode(CardFaceJSON(face), forKey: .face)
            try container.encode(peeksLeft, forKey: .peeksLeft)
        case .error(let error):
            try container.encode("error", forKey: .type)
            try container.encode(error.code, forKey: .code)
            try container.encode(error.message, forKey: .message)
        case .kicked:
            try container.encode("kicked", forKey: .type)
        }
    }
}

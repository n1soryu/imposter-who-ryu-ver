/// Why a host-mode request was refused. Each case maps to one error code on the wire.
public enum HostError: Error, Hashable, Sendable {
    case nameEmpty
    case nameTooLong(limit: Int)
    case nameTaken(existing: String)
    case full(limit: Int)
    case roundInProgress
    case unknownToken
    case seatTaken
    case noPeeksLeft
    case notAllowed

    /// The code phones receive.
    public var code: String {
        switch self {
        case .nameEmpty: "nameEmpty"
        case .nameTooLong: "nameTooLong"
        case .nameTaken: "nameTaken"
        case .full: "full"
        case .roundInProgress: "roundInProgress"
        case .unknownToken: "unknownToken"
        case .seatTaken: "seatTaken"
        case .noPeeksLeft: "noPeeksLeft"
        case .notAllowed: "notAllowed"
        }
    }

    /// A plain sentence for the person who hit the error.
    public var message: String {
        switch self {
        case .nameEmpty: "Type a name to join."
        case .nameTooLong(let limit): "Names can be up to \(limit) characters."
        case .nameTaken(let existing): "Someone's already called \(existing)."
        case .full(let limit): "The table is full. \(limit) players is the most."
        case .roundInProgress: "A round is in progress. You can join when it ends."
        case .unknownToken: "That seat is gone. Join again."
        case .seatTaken: "That seat is already in use."
        case .noPeeksLeft: "No peeks left this round."
        case .notAllowed: "You can't do that right now."
        }
    }

    init(_ error: Roster.NameError) {
        switch error {
        case .empty: self = .nameEmpty
        case .tooLong(let limit): self = .nameTooLong(limit: limit)
        case .duplicate(let existing): self = .nameTaken(existing: existing)
        case .full(let limit): self = .full(limit: limit)
        }
    }
}

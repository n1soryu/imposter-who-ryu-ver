/// What a player secretly is this round.
public enum Role: Hashable, Codable, Sendable {
    case crew(word: String)
    /// `hint` is set when the hint mode is on.
    case imposter(hint: String?)
    /// An imposter holding a decoy word, who believes they're crew.
    case undercover(decoy: String)

    public var isImposter: Bool {
        switch self {
        case .crew: false
        case .imposter, .undercover: true
        }
    }

    /// What the player's card shows when they reveal it. An undercover imposter's card looks exactly like a crew card.
    public var cardFace: CardFace {
        switch self {
        case .crew(let word): .word(word)
        case .undercover(let decoy): .word(decoy)
        case .imposter(let hint): .imposter(hint: hint)
        }
    }
}

/// The visible face of a dealt card.
public enum CardFace: Hashable, Codable, Sendable {
    case word(String)
    case imposter(hint: String?)
}

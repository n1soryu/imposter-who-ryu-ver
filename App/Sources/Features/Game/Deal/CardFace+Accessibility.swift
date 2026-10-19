import ImposterKit

extension CardFace {
    /// What VoiceOver reads when the card is face up.
    var spokenDescription: String {
        switch self {
        case .word(let word): "The secret word is \(word)."
        case .imposter(let hint?): "You're the imposter. Your hint is \(hint)."
        case .imposter(nil): "You're the imposter."
        }
    }
}

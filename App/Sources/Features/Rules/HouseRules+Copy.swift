import ImposterKit

extension WordCard.Difficulty {
    var title: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        }
    }
}

extension GameSettings.ImposterIntel {
    var title: String {
        switch self {
        case .nothing: "Nothing"
        case .hint: "A hint word"
        case .decoy: "A similar word"
        }
    }

    var detail: String {
        switch self {
        case .nothing: "Their card just says Imposter. The classic way to play."
        case .hint: "A related word to help them bluff. Good for younger players."
        case .decoy: "A close cousin of the secret word. They won't know they're the imposter."
        }
    }
}

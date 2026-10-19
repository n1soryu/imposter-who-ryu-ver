import Foundation

/// Checks an imposter's guess against the secret word, ignoring case, accents, spacing, punctuation, a leading article and a trailing plural "s".
public enum GuessMatcher {
    public static func matches(_ guess: String, card: WordCard) -> Bool {
        let normalizedGuess = normalize(guess)
        guard normalizedGuess.isEmpty == false else { return false }
        return ([card.word] + card.aliases).contains { normalize($0) == normalizedGuess }
    }

    static func normalize(_ text: String) -> String {
        var words = text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.isEmpty == false }

        if words.count > 1, ["the", "a", "an"].contains(words[0]) {
            words.removeFirst()
        }
        var joined = words.joined()
        if joined.count > 3, joined.hasSuffix("s") {
            joined.removeLast()
        }
        return joined
    }
}

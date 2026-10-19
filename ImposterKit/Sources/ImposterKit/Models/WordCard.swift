/// A secret word plus everything the modes need around it.
public struct WordCard: Hashable, Codable, Sendable {
    public enum Difficulty: String, Hashable, Codable, Sendable, CaseIterable {
        case easy, medium, hard
    }

    /// The secret word the crew sees.
    public var word: String
    /// Related words handed to the imposter in hint mode. They point near the word without giving it away.
    public var hints: [String]
    /// Close cousins of the word, handed to the imposter in undercover mode.
    public var decoys: [String]
    /// Other spellings accepted when the imposter guesses the word.
    public var aliases: [String]
    public var difficulty: Difficulty

    public init(
        word: String,
        hints: [String] = [],
        decoys: [String] = [],
        aliases: [String] = [],
        difficulty: Difficulty = .medium
    ) {
        self.word = word
        self.hints = hints
        self.decoys = decoys
        self.aliases = aliases
        self.difficulty = difficulty
    }

    private enum CodingKeys: String, CodingKey {
        case word, hints, decoys, aliases, difficulty
    }

    // Content files only need `word`; everything else is optional.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        word = try container.decode(String.self, forKey: .word)
        hints = try container.decodeIfPresent([String].self, forKey: .hints) ?? []
        decoys = try container.decodeIfPresent([String].self, forKey: .decoys) ?? []
        aliases = try container.decodeIfPresent([String].self, forKey: .aliases) ?? []
        difficulty = try container.decodeIfPresent(Difficulty.self, forKey: .difficulty) ?? .medium
    }
}

/// A themed deck of word cards, such as "Food" or "Movies".
public struct WordCategory: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public var name: String
    /// An emoji shown next to the name.
    public var symbol: String
    public var cards: [WordCard]

    public init(id: String, name: String, symbol: String, cards: [WordCard]) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.cards = cards
    }
}

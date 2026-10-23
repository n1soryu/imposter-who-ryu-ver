/// Everything chosen on the house rules screen: the game settings plus which words are in play.
public struct HouseRules: Hashable, Codable, Sendable {
    /// Whether the secret word is a single word, like "Pizza", or several, like "Ice Cream".
    public enum WordLength: String, Hashable, Codable, Sendable, CaseIterable {
        case any
        case oneWord
        /// Two or more words. Longer titles such as "Back to the Future" count here too.
        case multipleWords

        public func allows(_ card: WordCard) -> Bool {
            switch self {
            case .any: true
            case .oneWord: card.wordCount == 1
            case .multipleWords: card.wordCount > 1
            }
        }
    }

    public var settings: GameSettings
    public var categoryIDs: Set<WordCategory.ID>
    public var difficulties: Set<WordCard.Difficulty>
    public var wordLength: WordLength

    public init(
        settings: GameSettings = GameSettings(),
        categoryIDs: Set<WordCategory.ID>,
        difficulties: Set<WordCard.Difficulty> = Set(WordCard.Difficulty.allCases),
        wordLength: WordLength = .any
    ) {
        self.settings = settings
        self.categoryIDs = categoryIDs
        self.difficulties = difficulties
        self.wordLength = wordLength
    }

    private enum CodingKeys: String, CodingKey {
        case settings, categoryIDs, difficulties, wordLength
    }

    // Rules saved before `wordLength` existed still load.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        settings = try container.decode(GameSettings.self, forKey: .settings)
        categoryIDs = try container.decode(Set<WordCategory.ID>.self, forKey: .categoryIDs)
        difficulties = try container.decode(Set<WordCard.Difficulty>.self, forKey: .difficulties)
        wordLength = try container.decodeIfPresent(WordLength.self, forKey: .wordLength) ?? .any
    }

    /// Default rules with every category in the library switched on.
    public static func defaults(for library: WordLibrary) -> HouseRules {
        HouseRules(categoryIDs: Set(library.categories.map(\.id)))
    }

    /// The chosen categories that still exist in the library.
    public func categories(in library: WordLibrary) -> [WordCategory] {
        library.categories(withIDs: categoryIDs)
    }

    /// Whether the card's difficulty and length are allowed. Category is checked separately.
    public func allows(_ card: WordCard) -> Bool {
        difficulties.contains(card.difficulty) && wordLength.allows(card)
    }

    /// How many words match the chosen categories, difficulties and word length.
    public func availableCardCount(in library: WordLibrary) -> Int {
        categories(in: library).reduce(0) { total, category in
            total + category.cards.filter(allows).count
        }
    }

    /// Copies the rules with the imposter count brought into range for the group size.
    public func fitted(toPlayers playerCount: Int) -> HouseRules {
        var copy = self
        let maximum = GameSettings.maximumImposters(forPlayers: playerCount)
        copy.settings.imposterCount = min(max(settings.imposterCount, 1), maximum)
        return copy
    }

    /// Drops categories that are no longer in the library. If nothing is left, it switches every category back on.
    public func pruned(to library: WordLibrary) -> HouseRules {
        var copy = self
        let known = Set(library.categories.map(\.id))
        copy.categoryIDs = categoryIDs.intersection(known)
        if copy.categoryIDs.isEmpty {
            copy.categoryIDs = known
        }
        if copy.difficulties.isEmpty {
            copy.difficulties = Set(WordCard.Difficulty.allCases)
        }
        return copy
    }
}

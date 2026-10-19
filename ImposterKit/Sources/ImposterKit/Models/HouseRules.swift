/// Everything chosen on the house rules screen: the game settings plus which words are in play.
public struct HouseRules: Hashable, Codable, Sendable {
    public var settings: GameSettings
    public var categoryIDs: Set<WordCategory.ID>
    public var difficulties: Set<WordCard.Difficulty>

    public init(
        settings: GameSettings = GameSettings(),
        categoryIDs: Set<WordCategory.ID>,
        difficulties: Set<WordCard.Difficulty> = Set(WordCard.Difficulty.allCases)
    ) {
        self.settings = settings
        self.categoryIDs = categoryIDs
        self.difficulties = difficulties
    }

    /// Default rules with every category in the library switched on.
    public static func defaults(for library: WordLibrary) -> HouseRules {
        HouseRules(categoryIDs: Set(library.categories.map(\.id)))
    }

    /// The chosen categories that still exist in the library.
    public func categories(in library: WordLibrary) -> [WordCategory] {
        library.categories(withIDs: categoryIDs)
    }

    /// How many words match the chosen categories and difficulties.
    public func availableCardCount(in library: WordLibrary) -> Int {
        categories(in: library).reduce(0) { total, category in
            total + category.cards.filter { difficulties.contains($0.difficulty) }.count
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

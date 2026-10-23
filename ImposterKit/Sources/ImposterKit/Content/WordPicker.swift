/// A card drawn for a round, plus the category it came from.
public struct WordDraw: Hashable, Sendable {
    public let categoryID: WordCategory.ID
    public let categoryName: String
    public let categorySymbol: String
    public let card: WordCard
}

/// Draws secret words without repeats. Every eligible word comes up once before any word repeats.
///
/// Save this between launches so words don't repeat across game nights.
public struct WordPicker: Hashable, Codable, Sendable {
    /// Words already drawn, per category. Keys are lowercased words.
    public private(set) var used: [WordCategory.ID: Set<String>]

    public init() {
        used = [:]
    }

    /// Draws a card from the given categories, choosing the category first so small categories come up as often as big ones.
    /// - Parameter isEligible: Which cards may be drawn, such as `HouseRules.allows(_:)`.
    /// - Returns: `nil` when the categories hold no eligible cards.
    public mutating func draw(
        from categories: [WordCategory],
        where isEligible: (WordCard) -> Bool = { _ in true }
    ) -> WordDraw? {
        var generator = SystemRandomNumberGenerator()
        return draw(from: categories, where: isEligible, using: &generator)
    }

    public mutating func draw(
        from categories: [WordCategory],
        where isEligible: (WordCard) -> Bool = { _ in true },
        using generator: inout some RandomNumberGenerator
    ) -> WordDraw? {
        let eligible = categories.map { category in
            (category, category.cards.filter(isEligible))
        }
        guard eligible.contains(where: { $0.1.isEmpty == false }) else { return nil }

        var remaining = eligible.map { category, cards in
            (category, cards.filter { isUsed($0, in: category.id) == false })
        }
        if remaining.allSatisfy({ $0.1.isEmpty }) {
            // Every eligible word has been played, so start a fresh cycle for these words only.
            for (category, cards) in eligible {
                used[category.id]?.subtract(cards.map(Self.key))
            }
            remaining = eligible
        }

        let choices = remaining.filter { $0.1.isEmpty == false }
        guard let (category, cards) = choices.randomElement(using: &generator),
              let card = cards.randomElement(using: &generator)
        else { return nil }

        used[category.id, default: []].insert(Self.key(card))
        return WordDraw(categoryID: category.id, categoryName: category.name, categorySymbol: category.symbol, card: card)
    }

    public func isUsed(_ card: WordCard, in categoryID: WordCategory.ID) -> Bool {
        used[categoryID]?.contains(Self.key(card)) ?? false
    }

    public mutating func reset() {
        used = [:]
    }

    private static func key(_ card: WordCard) -> String {
        card.word.lowercased()
    }
}

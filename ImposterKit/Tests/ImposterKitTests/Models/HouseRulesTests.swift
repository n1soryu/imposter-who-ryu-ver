import Testing
@testable import ImposterKit

struct HouseRulesTests {
    static let library = WordLibrary(categories: [
        WordCategory(id: "food", name: "Food", symbol: "🍕", cards: [
            WordCard(word: "Pizza", difficulty: .easy),
            WordCard(word: "Paella", difficulty: .hard),
        ]),
        WordCategory(id: "pets", name: "Pets", symbol: "🐶", cards: [
            WordCard(word: "Dog", difficulty: .easy),
        ]),
    ])

    @Test func defaultsSwitchOnEveryCategory() {
        let rules = HouseRules.defaults(for: Self.library)

        #expect(rules.categoryIDs == ["food", "pets"])
        #expect(rules.difficulties == Set(WordCard.Difficulty.allCases))
        #expect(rules.availableCardCount(in: Self.library) == 3)
    }

    @Test func countsOnlyMatchingWords() {
        let rules = HouseRules(categoryIDs: ["food"], difficulties: [.easy])
        #expect(rules.availableCardCount(in: Self.library) == 1)
    }

    @Test("Fits the imposter count to the group", arguments: [(1, 5, 1), (3, 5, 2), (4, 3, 1), (0, 8, 1)])
    func fitsImpostersToTheGroup(requested: Int, players: Int, expected: Int) {
        var rules = HouseRules.defaults(for: Self.library)
        rules.settings.imposterCount = requested

        #expect(rules.fitted(toPlayers: players).settings.imposterCount == expected)
    }

    @Test func pruningDropsRemovedCategories() {
        let rules = HouseRules(categoryIDs: ["food", "gone"])
        #expect(rules.pruned(to: Self.library).categoryIDs == ["food"])
    }

    @Test func pruningNeverLeavesNothingToPlay() {
        let rules = HouseRules(categoryIDs: ["gone"], difficulties: [])
        let pruned = rules.pruned(to: Self.library)

        #expect(pruned.categoryIDs == ["food", "pets"])
        #expect(pruned.difficulties == Set(WordCard.Difficulty.allCases))
    }
}

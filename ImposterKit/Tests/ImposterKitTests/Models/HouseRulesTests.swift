import Foundation
import Testing
@testable import ImposterKit

struct HouseRulesTests {
    static let library = WordLibrary(categories: [
        WordCategory(id: "food", name: "Food", symbol: "🍕", cards: [
            WordCard(word: "Pizza", difficulty: .easy),
            WordCard(word: "Paella", difficulty: .hard),
            WordCard(word: "Ice Cream", difficulty: .easy),
            WordCard(word: "Mac and Cheese", difficulty: .medium),
        ]),
        WordCategory(id: "pets", name: "Pets", symbol: "🐶", cards: [
            WordCard(word: "Dog", difficulty: .easy),
        ]),
    ])

    @Test func defaultsSwitchOnEveryCategory() {
        let rules = HouseRules.defaults(for: Self.library)

        #expect(rules.categoryIDs == ["food", "pets"])
        #expect(rules.difficulties == Set(WordCard.Difficulty.allCases))
        #expect(rules.wordLength == .any)
        #expect(rules.availableCardCount(in: Self.library) == 5)
    }

    @Test func countsOnlyMatchingWords() {
        let rules = HouseRules(categoryIDs: ["food"], difficulties: [.easy])
        #expect(rules.availableCardCount(in: Self.library) == 2)
    }

    @Test("Word length filters by how many words the secret word has", arguments: [
        (HouseRules.WordLength.any, 5),
        (.oneWord, 3),
        (.multipleWords, 2),
    ])
    func filtersByWordLength(length: HouseRules.WordLength, expected: Int) {
        let rules = HouseRules(categoryIDs: ["food", "pets"], wordLength: length)
        #expect(rules.availableCardCount(in: Self.library) == expected)
    }

    @Test func wordLengthCombinesWithDifficulty() {
        let rules = HouseRules(categoryIDs: ["food"], difficulties: [.easy], wordLength: .multipleWords)

        #expect(rules.allows(WordCard(word: "Ice Cream", difficulty: .easy)))
        #expect(rules.allows(WordCard(word: "Pizza", difficulty: .easy)) == false)
        #expect(rules.allows(WordCard(word: "Mac and Cheese", difficulty: .medium)) == false)
    }

    @Test func rulesSavedBeforeWordLengthStillLoad() throws {
        var saved = try JSONSerialization.jsonObject(with: JSONEncoder().encode(HouseRules(categoryIDs: ["food"]))) as? [String: Any]
        saved?.removeValue(forKey: "wordLength")
        let data = try JSONSerialization.data(withJSONObject: try #require(saved))

        let rules = try JSONDecoder().decode(HouseRules.self, from: data)
        #expect(rules.categoryIDs == ["food"])
        #expect(rules.wordLength == .any)
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

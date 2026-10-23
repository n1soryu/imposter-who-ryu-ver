import Foundation
import Testing
@testable import ImposterKit

struct WordPickerTests {
    static let fruit = WordCategory(id: "fruit", name: "Fruit", symbol: "🍎", cards: [
        WordCard(word: "Apple", difficulty: .easy),
        WordCard(word: "Banana", difficulty: .easy),
        WordCard(word: "Durian", difficulty: .hard),
    ])
    static let pets = WordCategory(id: "pets", name: "Pets", symbol: "🐶", cards: [
        WordCard(word: "Dog", difficulty: .easy),
        WordCard(word: "Hamster", difficulty: .medium),
    ])

    @Test func drawsEveryWordOnceBeforeRepeating() throws {
        var picker = WordPicker()
        var generator = SeededGenerator(seed: 7)

        var words: [String] = []
        for _ in 0..<5 {
            let draw = picker.draw(from: [Self.fruit, Self.pets], using: &generator)
            words.append(try #require(draw).card.word)
        }

        #expect(Set(words) == ["Apple", "Banana", "Durian", "Dog", "Hamster"])
    }

    @Test func startsAFreshCycleOnceEverythingIsUsed() throws {
        var picker = WordPicker()
        var generator = SeededGenerator(seed: 3)
        for _ in 0..<5 {
            _ = picker.draw(from: [Self.fruit, Self.pets], using: &generator)
        }

        let sixthDraw = picker.draw(from: [Self.fruit, Self.pets], using: &generator)
        let sixth = try #require(sixthDraw)

        #expect(picker.used.values.reduce(0) { $0 + $1.count } == 1, "Only the newly drawn word should be marked used")
        #expect(picker.isUsed(sixth.card, in: sixth.categoryID))
    }

    @Test func respectsTheDifficultyFilter() throws {
        var picker = WordPicker()
        var generator = SeededGenerator(seed: 11)

        var words: [String] = []
        for _ in 0..<6 {
            let draw = picker.draw(from: [Self.fruit, Self.pets], where: { $0.difficulty == .easy }, using: &generator)
            words.append(try #require(draw).card.word)
        }

        #expect(Set(words) == ["Apple", "Banana", "Dog"])
    }

    @Test func refreshingOneFilterKeepsHistoryForOtherWords() throws {
        var picker = WordPicker()
        var generator = SeededGenerator(seed: 5)
        let hardDraw = picker.draw(from: [Self.fruit], where: { $0.difficulty == .hard }, using: &generator)
        let hard = try #require(hardDraw)
        #expect(hard.card.word == "Durian")

        // Use up the easy fruit and start one more easy cycle; Durian must stay marked as used.
        for _ in 0..<3 {
            _ = picker.draw(from: [Self.fruit], where: { $0.difficulty == .easy }, using: &generator)
        }

        #expect(picker.isUsed(hard.card, in: "fruit"))
    }

    @Test func returnsNothingWhenNoCardsQualify() {
        var picker = WordPicker()
        #expect(picker.draw(from: [Self.pets], where: { $0.difficulty == .hard }) == nil)
        #expect(picker.draw(from: []) == nil)
    }

    @Test func drawCarriesCategoryDetails() throws {
        var picker = WordPicker()
        let pending = picker.draw(from: [Self.pets])
        let draw = try #require(pending)

        #expect(draw.categoryID == "pets")
        #expect(draw.categoryName == "Pets")
        #expect(draw.categorySymbol == "🐶")
    }

    @Test func historySurvivesEncoding() throws {
        var picker = WordPicker()
        _ = picker.draw(from: [Self.fruit])

        let restored = try JSONDecoder().decode(WordPicker.self, from: JSONEncoder().encode(picker))

        #expect(restored == picker)
    }

    @Test func resetClearsHistory() {
        var picker = WordPicker()
        _ = picker.draw(from: [Self.fruit])
        picker.reset()

        #expect(picker.used.isEmpty)
    }
}

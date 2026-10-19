import Foundation
import Testing
@testable import ImposterKit

struct CustomPackTests {
    @Test func newPacksAreMarkedCustom() {
        let pack = WordCategory.custom(name: "Inside jokes", symbol: "😂")

        #expect(pack.isCustom)
        #expect(pack.cards.isEmpty)
        #expect(WordCategory(id: "food", name: "Food", symbol: "🍕", cards: []).isCustom == false)
    }

    @Test func eachPackGetsItsOwnID() {
        #expect(WordCategory.custom(name: "A", symbol: "🅰️").id != WordCategory.custom(name: "A", symbol: "🅰️").id)
    }

    // MARK: Adding words

    @Test func addsAWordWithCleanedHintsAndDecoys() throws {
        var pack = WordCategory.custom(name: "Trips", symbol: "🧳")

        let card = try pack.addWord("  Lake   Como ", hints: ["Boat", " ", "boat", "Lake Como trip"], decoys: ["Garda", ""])

        #expect(card.word == "Lake Como")
        #expect(card.hints == ["Boat"], "Blanks, duplicates and hints that contain the word are dropped")
        #expect(card.decoys == ["Garda"])
        #expect(pack.cards == [card])
    }

    @Test(arguments: ["", "   "])
    func rejectsBlankWords(word: String) {
        var pack = WordCategory.custom(name: "Trips", symbol: "🧳")
        #expect(throws: PackError.emptyWord) {
            try pack.addWord(word)
        }
    }

    @Test func rejectsLongWords() {
        var pack = WordCategory.custom(name: "Trips", symbol: "🧳")
        #expect(throws: PackError.wordTooLong(limit: 40)) {
            try pack.addWord(String(repeating: "a", count: 41))
        }
    }

    @Test(arguments: ["paris", "PARIS", "  Paris "])
    func rejectsDuplicateWords(word: String) throws {
        var pack = WordCategory.custom(name: "Trips", symbol: "🧳")
        try pack.addWord("Paris")

        #expect(throws: PackError.duplicateWord(existing: "Paris")) {
            try pack.addWord(word)
        }
    }

    // MARK: Editing

    @Test func updatesAWordInPlace() throws {
        var pack = WordCategory.custom(name: "Trips", symbol: "🧳")
        try pack.addWord("Paris")
        try pack.addWord("Rome")

        try pack.updateWord("Paris", to: "Paris Disneyland", hints: ["Castle"], decoys: ["Eurostar"])

        #expect(pack.cards.map(\.word) == ["Paris Disneyland", "Rome"])
        #expect(pack.cards[0].hints == ["Castle"])
    }

    @Test func updatingCanKeepTheSameWord() throws {
        var pack = WordCategory.custom(name: "Trips", symbol: "🧳")
        try pack.addWord("Paris")

        try pack.updateWord("Paris", to: "paris", hints: ["Eiffel"], decoys: [])

        #expect(pack.cards.map(\.word) == ["paris"])
    }

    @Test func updatingToAnotherWordInThePackFails() throws {
        var pack = WordCategory.custom(name: "Trips", symbol: "🧳")
        try pack.addWord("Paris")
        try pack.addWord("Rome")

        #expect(throws: PackError.duplicateWord(existing: "Rome")) {
            try pack.updateWord("Paris", to: "rome", hints: [], decoys: [])
        }
    }

    @Test func removesWords() throws {
        var pack = WordCategory.custom(name: "Trips", symbol: "🧳")
        for word in ["A", "B", "C"] { try pack.addWord(word) }

        pack.removeWords(atOffsets: [0, 2])

        #expect(pack.cards.map(\.word) == ["B"])
    }

    // MARK: Pasting lists

    @Test func addsAPastedListSkippingBlanksAndDuplicates() throws {
        var pack = WordCategory.custom(name: "Trips", symbol: "🧳")
        try pack.addWord("Paris")

        let added = pack.addWords(fromList: "Rome\n\n  Lisbon , paris\nBerlin,Rome")

        #expect(added == 3)
        #expect(pack.cards.map(\.word) == ["Paris", "Rome", "Lisbon", "Berlin"])
    }

    @Test(arguments: [
        ("a, b,  ,c", ["a", "b", "c"]),
        ("", []),
        (" single ", ["single"]),
    ])
    func splitsCommaLists(input: String, expected: [String]) {
        #expect(WordCategory.splitList(input) == expected)
    }

    // MARK: Library

    @Test func mergingAddsPacksAfterBundledCategoriesSortedByName() {
        let food = WordCategory(id: "food", name: "Food", symbol: "🍕", cards: [])
        let zoo = WordCategory.custom(name: "Zoo trip", symbol: "🦓")
        let anime = WordCategory.custom(name: "anime", symbol: "🍥")

        let merged = WordLibrary(categories: [food]).merging([zoo, anime])

        #expect(merged.categories.map(\.name) == ["Food", "anime", "Zoo trip"])
    }

    @Test func mergingTwiceDoesNotDuplicatePacks() {
        let pack = WordCategory.custom(name: "Trips", symbol: "🧳")
        let merged = WordLibrary(categories: []).merging([pack]).merging([pack])

        #expect(merged.categories.count == 1)
    }
}

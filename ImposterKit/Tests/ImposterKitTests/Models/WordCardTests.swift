import Foundation
import Testing
@testable import ImposterKit

struct WordCardTests {
    @Test func decodingFillsDefaultsForMissingFields() throws {
        let json = Data(#"{ "word": "Taco" }"#.utf8)
        let card = try JSONDecoder().decode(WordCard.self, from: json)

        #expect(card.word == "Taco")
        #expect(card.hints.isEmpty)
        #expect(card.decoys.isEmpty)
        #expect(card.aliases.isEmpty)
        #expect(card.difficulty == .medium)
    }

    @Test func decodingReadsEveryField() throws {
        let json = Data(#"""
        { "word": "Taco", "hints": ["Shell"], "decoys": ["Burrito"], "aliases": ["Tacos"], "difficulty": "easy" }
        """#.utf8)
        let card = try JSONDecoder().decode(WordCard.self, from: json)

        #expect(card == WordCard(word: "Taco", hints: ["Shell"], decoys: ["Burrito"], aliases: ["Tacos"], difficulty: .easy))
    }

    @Test func decodingWithoutWordFails() {
        let json = Data(#"{ "hints": ["Shell"] }"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(WordCard.self, from: json)
        }
    }

    @Test("Counts words, splitting on spaces and hyphens", arguments: [
        ("Pizza", 1),
        ("Ice Cream", 2),
        ("Spider-Man", 2),
        ("E.T.", 1),
        ("  Back to the  Future ", 4),
    ])
    func countsWords(word: String, expected: Int) {
        #expect(WordCard(word: word).wordCount == expected)
    }
}

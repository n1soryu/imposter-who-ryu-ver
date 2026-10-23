import Foundation
import Testing
@testable import ImposterKit

extension WordCategory: CustomTestStringConvertible {
    public var testDescription: String { name }
}

/// Quality rules every bundled category must meet, so a bad hint or decoy never reaches a game.
@Suite(.tags(.content))
struct BundledContentTests {
    static let categories = (try? WordLibrary.bundled().categories) ?? []

    @Test func libraryLoadsEveryCategory() throws {
        let library = try WordLibrary.bundled()

        #expect(library.categories.count >= 12)
        #expect(Set(library.categories.map(\.id)).count == library.categories.count, "Category IDs must be unique")
    }

    @Test(arguments: categories)
    func categoryHasEnoughWordsAtEveryDifficulty(category: WordCategory) {
        #expect(category.cards.count >= 45)
        for difficulty in WordCard.Difficulty.allCases {
            #expect(category.cards.contains { $0.difficulty == difficulty }, "\(category.name) has no \(difficulty) words")
        }
    }

    @Test(arguments: categories)
    func categoryHasNoDuplicateWords(category: WordCategory) {
        var seen: [String: String] = [:]
        for card in category.cards {
            let key = GuessMatcher.normalize(card.word)
            if let previous = seen[key] {
                Issue.record("\(category.name): \"\(card.word)\" duplicates \"\(previous)\"")
            }
            seen[key] = card.word
        }
    }

    @Test(arguments: categories)
    func everyCardHelpsAnImposter(category: WordCategory) {
        for card in category.cards {
            #expect(card.hints.count >= 3, "\(card.word) needs at least three hints")
            #expect(card.decoys.count >= 2, "\(card.word) needs at least two decoys")
        }
    }

    @Test(arguments: categories)
    func hintsAreShort(category: WordCategory) {
        for card in category.cards {
            for hint in card.hints {
                #expect(Self.words(in: hint).count <= 4, "Hint \"\(hint)\" for \(card.word) is too long to read at a glance")
            }
        }
    }

    @Test(arguments: categories)
    func hintsNeverGiveTheWordAway(category: WordCategory) {
        for card in category.cards {
            let answers = [card.word] + card.aliases
            let normalizedAnswers = answers.map(GuessMatcher.normalize)
            let answerWords = Set(answers.flatMap(Self.words))
            for hint in card.hints {
                let normalizedHint = GuessMatcher.normalize(hint)
                #expect(normalizedAnswers.allSatisfy { normalizedHint.contains($0) == false }, "Hint \"\(hint)\" gives away \(card.word)")
                #expect(normalizedAnswers.allSatisfy { normalizedHint.count < 4 || $0.contains(normalizedHint) == false }, "Hint \"\(hint)\" is part of \(card.word)")
                #expect(answerWords.isDisjoint(with: Self.words(in: hint)), "Hint \"\(hint)\" shares a word with \(card.word)")
            }
        }
    }

    /// The imposter gets one hint at random, so each hint has to point at its own card and no other.
    @Test(arguments: categories)
    func hintsPointAtOneCard(category: WordCategory) {
        let otherWords = Dictionary(
            category.cards.flatMap { card in ([card.word] + card.aliases).map { (GuessMatcher.normalize($0), card.word) } },
            uniquingKeysWith: { first, _ in first }
        )
        var hintOwners: [String: String] = [:]
        for card in category.cards {
            for hint in card.hints {
                let key = GuessMatcher.normalize(hint)
                if let owner = hintOwners[key], owner != card.word {
                    Issue.record("\(category.name): hint \"\(hint)\" is used by both \(owner) and \(card.word)")
                }
                hintOwners[key] = card.word
                if let other = otherWords[key], other != card.word {
                    Issue.record("\(category.name): hint \"\(hint)\" for \(card.word) is another card, \(other)")
                }
            }
        }
    }

    @Test(arguments: categories)
    func decoysAreNotHints(category: WordCategory) {
        for card in category.cards {
            let hints = Set(card.hints.map(GuessMatcher.normalize))
            for decoy in card.decoys {
                #expect(hints.contains(GuessMatcher.normalize(decoy)) == false, "\(card.word) uses \"\(decoy)\" as both a hint and a decoy")
            }
        }
    }

    @Test(arguments: categories)
    func decoysAreNeverAcceptedAsTheWord(category: WordCategory) {
        for card in category.cards {
            for decoy in card.decoys {
                #expect(GuessMatcher.matches(decoy, card: card) == false, "Decoy \"\(decoy)\" would count as guessing \(card.word)")
            }
        }
    }

    /// The meaningful words in a text, singularized, so "Lion cub" and "The Lion King" both contain "lion".
    static func words(in text: String) -> Set<String> {
        let ignored: Set<String> = ["the", "a", "an", "of", "and", "in", "on", "to", "for"]
        return Set(
            text.components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.isEmpty == false }
                .map(GuessMatcher.normalize)
                .filter { $0.count >= 3 && ignored.contains($0) == false }
        )
    }
}

extension Tag {
    @Tag static var content: Self
}

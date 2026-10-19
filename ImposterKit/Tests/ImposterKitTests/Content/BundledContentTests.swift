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
        #expect(category.cards.count >= 30)
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
            #expect(card.hints.count >= 2, "\(card.word) needs at least two hints")
            #expect(card.decoys.isEmpty == false, "\(card.word) needs a decoy")
        }
    }

    @Test(arguments: categories)
    func hintsNeverGiveTheWordAway(category: WordCategory) {
        for card in category.cards {
            let answers = ([card.word] + card.aliases).map(GuessMatcher.normalize)
            for hint in card.hints {
                let normalizedHint = GuessMatcher.normalize(hint)
                #expect(answers.allSatisfy { normalizedHint.contains($0) == false }, "Hint \"\(hint)\" gives away \(card.word)")
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
}

extension Tag {
    @Tag static var content: Self
}

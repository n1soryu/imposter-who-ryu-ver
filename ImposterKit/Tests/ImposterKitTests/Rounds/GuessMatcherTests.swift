import Testing
@testable import ImposterKit

struct GuessMatcherTests {
    static let card = WordCard(word: "Ice Cream", aliases: ["Gelato"])

    @Test("Accepts reasonable spellings", arguments: [
        "Ice Cream", "ice cream", "  ICE CREAM ", "icecream", "ice-cream", "Ice creams", "the ice cream", "Gelato", "gelatos",
    ])
    func acceptsReasonableSpellings(guess: String) {
        #expect(GuessMatcher.matches(guess, card: Self.card))
    }

    @Test("Rejects wrong or empty guesses", arguments: ["", "   ", "Ice", "Cream", "Frozen yogurt", "the"])
    func rejectsWrongGuesses(guess: String) {
        #expect(GuessMatcher.matches(guess, card: Self.card) == false)
    }

    @Test func ignoresAccents() {
        #expect(GuessMatcher.matches("Creme brulee", card: WordCard(word: "Crème brûlée")))
    }

    @Test func keepsShortWordsEndingInS() {
        #expect(GuessMatcher.normalize("Bus") == "bus")
        #expect(GuessMatcher.matches("Bu", card: WordCard(word: "Bus")) == false)
    }
}

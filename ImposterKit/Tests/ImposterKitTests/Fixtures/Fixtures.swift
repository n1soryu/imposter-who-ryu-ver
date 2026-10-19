import Foundation
@testable import ImposterKit

/// SplitMix64: a tiny deterministic generator so random dealing is repeatable in tests.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

enum Fixtures {
    static let names = ["Ryu", "Aiko", "Ben", "Chloe", "Dev", "Ema", "Finn", "Gia", "Hana", "Ivan", "Jun", "Kai"]

    static func players(_ count: Int) -> [Player] {
        names.prefix(count).map { Player(name: $0) }
    }

    static let pizza = WordCard(
        word: "Pizza",
        hints: ["Slice", "Oven"],
        decoys: ["Calzone"],
        aliases: ["Pizza pie"]
    )

    static let bareCard = WordCard(word: "Thing")

    static func deal(
        players: [Player] = players(5),
        card: WordCard = pizza,
        settings: GameSettings = GameSettings(),
        seed: UInt64 = 1
    ) throws -> Round {
        var generator = SeededGenerator(seed: seed)
        return try RoundDealer.deal(players: players, card: card, categoryName: "Food", settings: settings, using: &generator)
    }
}

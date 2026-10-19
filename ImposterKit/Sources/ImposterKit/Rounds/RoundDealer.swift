/// Why a round couldn't be dealt.
public enum DealError: Error, Hashable, Sendable {
    case notEnoughPlayers(minimum: Int)
    case duplicatePlayers
    case invalidImposterCount(allowed: ClosedRange<Int>)
}

/// Assigns secret roles and picks who gives the first clue.
public enum RoundDealer {
    public static func deal(
        players: [Player],
        card: WordCard,
        categoryName: String,
        settings: GameSettings
    ) throws(DealError) -> Round {
        var generator = SystemRandomNumberGenerator()
        return try deal(players: players, card: card, categoryName: categoryName, settings: settings, using: &generator)
    }

    public static func deal(
        players: [Player],
        card: WordCard,
        categoryName: String,
        settings: GameSettings,
        using generator: inout some RandomNumberGenerator
    ) throws(DealError) -> Round {
        guard players.count >= GameSettings.minimumPlayers else {
            throw .notEnoughPlayers(minimum: GameSettings.minimumPlayers)
        }
        guard Set(players.map(\.id)).count == players.count else {
            throw .duplicatePlayers
        }
        let allowed = 1...GameSettings.maximumImposters(forPlayers: players.count)
        guard allowed.contains(settings.imposterCount) else {
            throw .invalidImposterCount(allowed: allowed)
        }

        let isTrollRound = settings.trollChance > 0 && Double.random(in: 0..<1, using: &generator) < settings.trollChance
        let imposters: Set<Player.ID> = isTrollRound
            ? Set(players.map(\.id))
            : Set(players.shuffled(using: &generator).prefix(settings.imposterCount).map(\.id))

        var roles: [Player.ID: Role] = [:]
        for player in players {
            roles[player.id] = imposters.contains(player.id)
                ? imposterRole(for: card, intel: settings.imposterIntel, isTrollRound: isTrollRound, using: &generator)
                : .crew(word: card.word)
        }

        // Starting with nothing to go on is brutal, so imposters are skipped as the first clue-giver unless the house rules allow it.
        let canStart = isTrollRound || settings.imposterMayStart
            ? Array(players.indices)
            : players.indices.filter { imposters.contains(players[$0].id) == false }
        let start = canStart.randomElement(using: &generator) ?? 0
        let turnOrder = (players[start...] + players[..<start]).map(\.id)

        return Round(
            players: players,
            card: card,
            categoryName: categoryName,
            settings: settings,
            roles: roles,
            turnOrder: turnOrder,
            isTrollRound: isTrollRound
        )
    }

    private static func imposterRole(
        for card: WordCard,
        intel: GameSettings.ImposterIntel,
        isTrollRound: Bool,
        using generator: inout some RandomNumberGenerator
    ) -> Role {
        switch intel {
        case .nothing:
            return .imposter(hint: nil)
        case .hint:
            return .imposter(hint: card.hints.randomElement(using: &generator))
        case .decoy:
            // In a troll round everyone would get the same decoy, which would just make a new crew, so trolls get a hint instead.
            if isTrollRound == false, let decoy = card.decoys.randomElement(using: &generator) {
                return .undercover(decoy: decoy)
            }
            return .imposter(hint: card.hints.randomElement(using: &generator))
        }
    }
}

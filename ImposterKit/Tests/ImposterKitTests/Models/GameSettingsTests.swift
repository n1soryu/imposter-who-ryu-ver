import Testing
@testable import ImposterKit

struct GameSettingsTests {
    @Test("Imposters stay a strict minority", arguments: [
        (3, 1), (4, 1), (5, 2), (6, 2), (7, 3), (10, 4), (15, 7),
    ])
    func maximumImposters(players: Int, expected: Int) {
        #expect(GameSettings.maximumImposters(forPlayers: players) == expected)
    }

    @Test func defaultsMatchClassicRules() {
        let settings = GameSettings()
        #expect(settings.imposterCount == 1)
        #expect(settings.imposterIntel == .nothing)
        #expect(settings.trollChance == 0)
        #expect(settings.lastChanceGuess)
    }
}

#if DEBUG
import Foundation
import ImposterKit

/// Debug builds only: launch straight into a screen with sample players, for screenshots and quick checks.
///
/// Pass `-scene <name>` as a launch argument, for example `xcrun simctl launch <device> com.n1soryu.imposter -scene results`.
enum DebugScene: String, CaseIterable {
    case players, rules, deal, clues, discussion, voting, lastChance, results, scoreboard

    static var requested: DebugScene? {
        UserDefaults.standard.string(forKey: "scene").flatMap(DebugScene.init(rawValue:))
    }

    /// Sets up the stores and returns the navigation path for this scene.
    @MainActor
    func prepare(roster: RosterStore, rules: RulesStore, game: GameStore, library: WordLibrary) -> [Route] {
        for name in ["Ryu", "Aiko", "Ben", "Chloe", "Dev"] where roster.players.contains(where: { $0.name == name }) == false {
            try? roster.add(name)
        }
        rules.rules.settings.turnSeconds = 30
        rules.rules.settings.discussionSeconds = 120

        switch self {
        case .players: return [.players]
        case .rules: return [.players, .rules]
        default: break
        }

        game.start(players: roster.players, rules: rules.rules, library: library)
        guard let round = game.session?.round else { return [.players, .rules] }
        let imposter = round.imposterIDs.first

        if self != .deal {
            game.perform { session in round.players.forEach { _ in session.cardSeen() } }
        }
        switch self {
        case .discussion:
            game.perform { $0.endClues() }
        case .voting:
            game.perform { $0.startVoting() }
        case .lastChance:
            game.perform { $0.accuse(imposter) }
        case .results, .scoreboard:
            game.perform { $0.accuse(imposter) }
            game.perform { $0.submitGuess(nil) }
        default:
            break
        }
        return [.players, .rules, .game]
    }
}
#endif

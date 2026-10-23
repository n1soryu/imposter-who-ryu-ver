import Foundation
import ImposterKit
import Observation

/// The game in progress, plus the word history that keeps words from repeating across game nights.
@Observable
@MainActor
final class GameStore {
    private(set) var session: GameSession?
    /// Why the last attempt to start or continue a game failed.
    var problem: String?

    @ObservationIgnored private let defaults: UserDefaults
    private static let historyKey = "wordHistory.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Deals the first round. Returns `false` and sets `problem` if the game can't start.
    @discardableResult
    func start(players: [Player], rules: HouseRules, library: WordLibrary) -> Bool {
        do {
            session = try GameSession(players: players, rules: rules, library: library, picker: savedPicker())
            problem = nil
            saveHistory()
            return true
        } catch {
            problem = error.message
            return false
        }
    }

    /// Applies a game action, such as `cardSeen()` or `castVote(by:for:)`.
    func perform(_ action: (inout GameSession) -> Void) {
        guard var session else { return }
        action(&session)
        self.session = session
    }

    func nextRound(library: WordLibrary) {
        guard var session else { return }
        do {
            try session.nextRound(library: library)
            self.session = session
            problem = nil
            saveHistory()
        } catch {
            problem = error.message
        }
    }

    func end() {
        session = nil
    }

    func clearProblem() {
        problem = nil
    }

    private func savedPicker() -> WordPicker {
        guard let data = defaults.data(forKey: Self.historyKey),
              let picker = try? JSONDecoder().decode(WordPicker.self, from: data)
        else { return WordPicker() }
        return picker
    }

    private func saveHistory() {
        guard let picker = session?.picker, let data = try? JSONEncoder().encode(picker) else { return }
        defaults.set(data, forKey: Self.historyKey)
    }
}

extension GameError {
    var message: String {
        switch self {
        case .noWords:
            "No words match these house rules. Turn on more categories or difficulties, or change the word length."
        case .deal(.notEnoughPlayers(let minimum)):
            "You need at least \(minimum) players."
        case .deal(.duplicatePlayers):
            "Two players have the same name. Rename one of them."
        case .deal(.invalidImposterCount(let allowed)):
            "Pick between \(allowed.lowerBound) and \(allowed.upperBound) imposters."
        }
    }
}

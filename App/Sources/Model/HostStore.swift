import ImposterHost
import ImposterKit
import Observation
import UIKit

/// The hosted game, from the lobby to the last round. It exists only while this phone is hosting.
@Observable
@MainActor
final class HostStore {
    private(set) var controller: HostController?
    /// Why the last attempt to deal a round failed.
    var problem: String?

    @ObservationIgnored private let history: WordHistory

    init(defaults: UserDefaults = .standard) {
        history = WordHistory(defaults: defaults)
    }

    var isHosting: Bool { controller != nil }

    /// Seats the host and starts listening for phones. The screen stays awake while hosting.
    func begin(hostName: String, library: WordLibrary) throws(HostError) {
        let controller = try HostController(hostName: hostName, library: library, picker: history.load())
        self.controller = controller
        problem = nil
        UIApplication.shared.isIdleTimerDisabled = true
        Task { await controller.startListening() }
    }

    /// Closes the listeners, drops every phone and lets the screen sleep again.
    func stop() {
        controller?.stopListening()
        controller = nil
        problem = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }

    /// Rebinds the same ports after the app was in the background. Phones reconnect by themselves.
    func restart() {
        guard let controller else { return }
        Task { await controller.restart() }
    }

    /// Deals round 1. Returns `false` and sets `problem` if the game can't start.
    @discardableResult
    func deal(rules: HouseRules) -> Bool {
        guard let controller else { return false }
        do {
            try controller.start(rules: rules, picker: history.load())
            problem = nil
            saveHistory()
            return true
        } catch {
            problem = error.message
            return false
        }
    }

    func nextRound() {
        guard let controller else { return }
        do {
            try controller.nextRound()
            problem = nil
            saveHistory()
        } catch {
            problem = error.message
        }
    }

    func clearProblem() {
        problem = nil
    }

    private func saveHistory() {
        if let picker = controller?.session.game?.picker { history.save(picker) }
    }
}

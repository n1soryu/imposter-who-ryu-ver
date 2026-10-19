import ImposterKit
import SwiftUI

/// The navigation stack from home, through setup, into a game.
struct RootView: View {
    @State private var path: [Route] = []

    @Environment(\.wordLibrary) private var library
    @Environment(RosterStore.self) private var roster
    @Environment(RulesStore.self) private var rules
    @Environment(GameStore.self) private var game

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(startNewGame: showPlayers)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .players: PlayersView(chooseRules: showRules)
                    case .rules: RulesView(deal: startGame)
                    case .game: GameView(leave: returnHome)
                    }
                }
        }
    }

    private func showPlayers() {
        path.append(.players)
    }

    private func showRules() {
        path.append(.rules)
    }

    private func startGame() {
        if game.start(players: roster.players, rules: rules.rules, library: library) {
            path.append(.game)
        }
    }

    private func returnHome() {
        path.removeAll()
    }
}

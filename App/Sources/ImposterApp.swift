import ImposterKit
import SwiftUI

@main
struct ImposterApp: App {
    private let library: WordLibrary
    @State private var rosterStore: RosterStore
    @State private var rulesStore: RulesStore
    @State private var gameStore = GameStore()

    init() {
        let library = WordLibrary.bundledOrEmpty()
        self.library = library
        _rosterStore = State(initialValue: RosterStore())
        _rulesStore = State(initialValue: RulesStore(library: library))
        NavigationBarAppearance.apply()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.wordLibrary, library)
                .environment(rosterStore)
                .environment(rulesStore)
                .environment(gameStore)
                .preferredColorScheme(.dark)
        }
    }
}

/// Screens reachable from the home screen, in the order a new game goes through them.
enum Route: Hashable {
    case players
    case rules
    case game
}

struct RootView: View {
    @State private var path: [Route] = []

    @Environment(\.wordLibrary) private var library
    @Environment(RosterStore.self) private var roster
    @Environment(RulesStore.self) private var rules
    @Environment(GameStore.self) private var game

    var body: some View {
        NavigationStack(path: $path) {
            HomeView { path.append(.players) }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .players:
                        PlayersView { path.append(.rules) }
                    case .rules:
                        RulesView {
                            if game.start(players: roster.players, rules: rules.rules, library: library) {
                                path.append(.game)
                            }
                        }
                    case .game:
                        GameView { path.removeAll() }
                    }
                }
        }
    }
}

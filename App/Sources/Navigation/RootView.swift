import ImposterKit
import SwiftUI

/// The navigation stack from home, through setup, into a game.
struct RootView: View {
    var bundledLibrary: WordLibrary

    @State private var path: [Route] = []

    @Environment(CustomPackStore.self) private var packs
    @Environment(RosterStore.self) private var roster
    @Environment(RulesStore.self) private var rules
    @Environment(GameStore.self) private var game

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(startNewGame: showPlayers)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .players: PlayersView(chooseRules: showRules)
                    case .rules: RulesView(deal: startGame, managePacks: showPacks)
                    case .packs: PacksView(openPack: showPack)
                    case .pack(let id): PackEditorView(packID: id)
                    case .game: GameView(leave: returnHome)
                    }
                }
        }
        .environment(\.wordLibrary, library)
        .onChange(of: packs.packs) {
            rules.prune(to: library)
        }
        #if DEBUG
        .task(applyDebugScene)
        #endif
    }

    /// Bundled categories plus the group's own packs.
    private var library: WordLibrary {
        bundledLibrary.merging(packs.packs)
    }

    private func showPlayers() {
        path.append(.players)
    }

    private func showRules() {
        path.append(.rules)
    }

    private func showPacks() {
        path.append(.packs)
    }

    private func showPack(_ id: WordCategory.ID) {
        path.append(.pack(id))
    }

    private func startGame() {
        if game.start(players: roster.players, rules: rules.rules, library: library) {
            path.append(.game)
        }
    }

    private func returnHome() {
        path.removeAll()
    }

    #if DEBUG
    private func applyDebugScene() async {
        guard let scene = DebugScene.requested else { return }
        path = scene.prepare(roster: roster, rules: rules, game: game, packs: packs, library: library)
    }
    #endif
}

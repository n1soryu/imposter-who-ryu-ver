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
    @Environment(HostStore.self) private var host
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(startNewGame: showPlayers, hostGame: showHostLobby)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .players: PlayersView(chooseRules: showRules)
                    case .rules: RulesView(deal: startGame, managePacks: showPacks)
                    case .packs: PacksView(openPack: showPack)
                    case .pack(let id): PackEditorView(packID: id)
                    case .game: GameView(leave: returnHome)
                    case .hostLobby: HostLobbyView(chooseRules: showHostRules)
                    case .hostRules: HostRulesView(deal: dealHostGame)
                    case .hostGame: HostGameView(backToLobby: returnToHostLobby, leave: leaveHostGame)
                    }
                }
        }
        .environment(\.wordLibrary, library)
        .onChange(of: packs.packs) {
            rules.prune(to: library)
        }
        .onChange(of: path) { _, path in
            // Hosting only lasts while one of the host screens is open, so backing out of the lobby stops it.
            let isOnHostScreen = path.contains { [.hostLobby, .hostRules, .hostGame].contains($0) }
            if isOnHostScreen == false && host.isHosting { host.stop() }
        }
        .onChange(of: scenePhase) { old, new in
            if old == .background && new == .active { host.restart() }
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

    private func showHostLobby() {
        path.append(.hostLobby)
    }

    private func showHostRules() {
        path.append(.hostRules)
    }

    private func dealHostGame() {
        if host.deal(rules: rules.rules) {
            path.append(.hostGame)
        }
    }

    /// The host ended the round for everyone, so the game goes back to the lobby with the same people.
    private func returnToHostLobby() {
        path = [.hostLobby]
    }

    private func leaveHostGame() {
        host.stop()
        path.removeAll()
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
        path = scene.prepare(roster: roster, rules: rules, game: game, host: host, packs: packs, library: library)
    }
    #endif
}

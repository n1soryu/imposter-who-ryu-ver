import ImposterKit
import SwiftUI

@main
struct ImposterApp: App {
    private let library = WordLibrary.bundledOrEmpty()
    @State private var rosterStore = RosterStore()

    init() {
        NavigationBarAppearance.apply()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.wordLibrary, library)
                .environment(rosterStore)
                .preferredColorScheme(.dark)
        }
    }
}

/// Screens reachable from the home screen, in the order a new game goes through them.
enum Route: Hashable {
    case players
    case rules
}

struct RootView: View {
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView { path.append(.players) }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .players: PlayersView { path.append(.rules) }
                    case .rules: RulesView()
                    }
                }
        }
    }
}

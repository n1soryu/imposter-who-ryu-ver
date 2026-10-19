import ImposterKit
import SwiftUI

@main
struct ImposterApp: App {
    private let library: WordLibrary
    @State private var rosterStore: RosterStore
    @State private var rulesStore: RulesStore

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
                .preferredColorScheme(.dark)
        }
    }
}

/// Screens reachable from the home screen, in the order a new game goes through them.
enum Route: Hashable {
    case players
    case rules
    case deal
}

struct RootView: View {
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView { path.append(.players) }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .players: PlayersView { path.append(.rules) }
                    case .rules: RulesView { path.append(.deal) }
                    case .deal: DealPlaceholderView()
                    }
                }
        }
    }
}

/// Placeholder for the card deal, which arrives with roadmap feature 1.4.
private struct DealPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Dealing is next",
            systemImage: "rectangle.portrait.on.rectangle.portrait",
            description: Text("Passing the phone and revealing cards arrives in the next build.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.felt)
    }
}

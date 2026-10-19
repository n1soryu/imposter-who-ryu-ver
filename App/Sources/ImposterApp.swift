import ImposterKit
import SwiftUI

@main
struct ImposterApp: App {
    private let library = WordLibrary.bundledOrEmpty()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.wordLibrary, library)
                .preferredColorScheme(.dark)
        }
    }
}

/// Screens reachable from the home screen.
enum Route: Hashable {
    case setup
}

struct RootView: View {
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView { path.append(.setup) }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .setup: SetupView()
                    }
                }
        }
    }
}

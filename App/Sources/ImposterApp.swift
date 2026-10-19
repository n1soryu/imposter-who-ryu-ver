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
                .tint(Color.crewInk)
        }
    }
}

import ImposterKit
import SwiftUI

@main
struct ImposterApp: App {
    private let bundledLibrary: WordLibrary
    @State private var packStore: CustomPackStore
    @State private var rosterStore: RosterStore
    @State private var rulesStore: RulesStore
    @State private var gameStore = GameStore()
    @State private var soundPlayer = SoundPlayer()

    init() {
        let bundled = WordLibrary.bundledOrEmpty()
        let packs = CustomPackStore()
        bundledLibrary = bundled
        _packStore = State(initialValue: packs)
        _rosterStore = State(initialValue: RosterStore())
        _rulesStore = State(initialValue: RulesStore(library: bundled.merging(packs.packs)))
        NavigationBarAppearance.apply()
    }

    var body: some Scene {
        WindowGroup {
            RootView(bundledLibrary: bundledLibrary)
                .environment(packStore)
                .environment(rosterStore)
                .environment(rulesStore)
                .environment(gameStore)
                .environment(soundPlayer)
                .preferredColorScheme(.dark)
                .tint(Color.crewInk)
                // Lists still scroll when they're long, but no screen shows a scroll bar.
                .scrollIndicators(.hidden)
        }
    }
}

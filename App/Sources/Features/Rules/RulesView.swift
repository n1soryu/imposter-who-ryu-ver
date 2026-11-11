import ImposterKit
import SwiftUI

/// Words, imposters, modes and timers for the next game.
struct RulesView: View {
    var deal: () -> Void
    /// Hidden when `nil`, such as in host mode, where the word library is fixed once hosting starts.
    var managePacks: (() -> Void)?
    /// How many people will play. Pass-and-play uses the saved roster; host mode passes the lobby's count.
    var playerCount: Int?
    /// Why dealing failed, when the caller keeps its own record of it.
    var dealProblem: String?

    @Environment(RulesStore.self) private var store
    @Environment(RosterStore.self) private var roster
    @Environment(GameStore.self) private var game
    @Environment(\.wordLibrary) private var library

    var body: some View {
        @Bindable var store = store
        let playerCount = playerCount ?? roster.players.count
        let wordsInPlay = store.rules.availableCardCount(in: library)

        Form {
            WordsSection(rules: $store.rules, library: library, wordsInPlay: wordsInPlay, managePacks: managePacks)
            ImpostersSection(settings: $store.rules.settings, playerCount: playerCount)
            ImposterIntelSection(intel: $store.rules.settings.imposterIntel)
            RoundsSection(settings: $store.rules.settings)
            HouseRulesSection(settings: $store.rules.settings)
        }
        .scrollContentBackground(.hidden)
        .background(Color.felt)
        .navigationTitle("House rules")
        .safeAreaInset(edge: .bottom) {
            DealBar(
                canDeal: wordsInPlay > 0 && playerCount >= GameSettings.minimumPlayers,
                problem: wordsInPlay == 0 ? "No words match. Pick more categories or difficulties, or change the word length." : dealProblem ?? game.problem,
                deal: deal
            )
        }
        .onAppear(perform: fitToGroup)
        .onChange(of: playerCount, fitToGroup)
    }

    private func fitToGroup() {
        store.fit(toPlayers: playerCount ?? roster.players.count)
    }
}

#Preview {
    let defaults = UserDefaults(suiteName: "preview-rules") ?? .standard
    let library = WordLibrary.bundledOrEmpty()
    let roster = RosterStore(defaults: defaults)
    for name in ["Ryu", "Aiko", "Ben", "Chloe", "Dev"] {
        try? roster.add(name)
    }
    return NavigationStack {
        RulesView {} managePacks: {}
    }
    .environment(\.wordLibrary, library)
    .environment(roster)
    .environment(RulesStore(library: library, defaults: defaults))
    .environment(GameStore(defaults: defaults))
    .environment(CustomPackStore(directory: .temporaryDirectory))
}

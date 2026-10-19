import ImposterKit
import SwiftUI

/// Words, imposters, modes and timers for the next game.
struct RulesView: View {
    var deal: () -> Void

    @Environment(RulesStore.self) private var store
    @Environment(RosterStore.self) private var roster
    @Environment(GameStore.self) private var game
    @Environment(\.wordLibrary) private var library

    var body: some View {
        @Bindable var store = store
        let playerCount = roster.players.count
        let wordsInPlay = store.rules.availableCardCount(in: library)

        Form {
            WordsSection(rules: $store.rules, library: library, wordsInPlay: wordsInPlay)
            ImpostersSection(settings: $store.rules.settings, playerCount: playerCount)
            ImposterIntelSection(intel: $store.rules.settings.imposterIntel)
            RoundsSection(settings: $store.rules.settings)
            HouseRulesSection(settings: $store.rules.settings)
        }
        .scrollContentBackground(.hidden)
        .background(Color.felt)
        .navigationTitle("House rules")
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button("Deal cards", action: deal)
                    .buttonStyle(.pill)
                    .disabled(wordsInPlay == 0 || playerCount < GameSettings.minimumPlayers)
                if wordsInPlay == 0 {
                    Text("Pick at least one category and difficulty.")
                        .font(.footnote)
                        .foregroundStyle(Color.imposterInk)
                } else if let problem = game.problem {
                    Text(problem)
                        .font(.footnote)
                        .foregroundStyle(Color.imposterInk)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 12)
            .background(Color.felt)
        }
        .onAppear {
            store.rules = store.rules.fitted(toPlayers: playerCount)
        }
    }
}

// MARK: - Words

private struct WordsSection: View {
    @Binding var rules: HouseRules
    var library: WordLibrary
    var wordsInPlay: Int

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 8)]

    var body: some View {
        Section {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(library.categories) { category in
                    SelectableChip(
                        title: category.name,
                        symbol: category.symbol,
                        isSelected: rules.categoryIDs.contains(category.id)
                    ) {
                        rules.categoryIDs.formSymmetricDifference([category.id])
                    }
                }
            }
            .padding(.vertical, 4)

            HStack(spacing: 8) {
                ForEach(WordCard.Difficulty.allCases, id: \.self) { difficulty in
                    SelectableChip(title: difficulty.title, isSelected: rules.difficulties.contains(difficulty)) {
                        rules.difficulties.formSymmetricDifference([difficulty])
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            HStack {
                SectionTitle("Words")
                Spacer()
                Button(allSelected ? "Clear all" : "Select all") {
                    rules.categoryIDs = allSelected ? [] : Set(library.categories.map(\.id))
                }
                .font(.subheadline.weight(.semibold))
                .textCase(nil)
            }
        } footer: {
            Text(wordsInPlay == 1 ? "1 word in play." : "\(wordsInPlay) words in play.")
        }
        .listRowBackground(Color.feltRaised)
    }

    private var allSelected: Bool {
        rules.categoryIDs.count == library.categories.count
    }
}

/// A tappable tag that's filled with crew ink when it's switched on.
private struct SelectableChip: View {
    var title: String
    var symbol: String?
    var isSelected: Bool
    var toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 6) {
                if let symbol {
                    Text(symbol).accessibilityHidden(true)
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 40)
            .padding(.horizontal, 10)
            .foregroundStyle(isSelected ? Color.felt : Color.cardStock)
            .background(isSelected ? Color.crewInk : Color.felt, in: .capsule)
            .overlay {
                Capsule().strokeBorder(isSelected ? Color.clear : Color.haze.opacity(0.5), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.snappy(duration: 0.15), value: isSelected)
    }
}

// MARK: - Imposters

private struct ImpostersSection: View {
    @Binding var settings: GameSettings
    var playerCount: Int

    var body: some View {
        let maximum = GameSettings.maximumImposters(forPlayers: playerCount)

        Section {
            Stepper(value: $settings.imposterCount, in: 1...maximum) {
                Text(settings.imposterCount == 1 ? "1 imposter" : "\(settings.imposterCount) imposters")
                    .foregroundStyle(Color.cardStock)
            }
        } header: {
            SectionTitle("Imposters")
        } footer: {
            Text(maximum == 1
                 ? "Add 5 or more players to have more than one imposter."
                 : "With \(playerCount) players you can have up to \(maximum).")
        }
        .listRowBackground(Color.feltRaised)
    }
}

private struct ImposterIntelSection: View {
    @Binding var intel: GameSettings.ImposterIntel

    var body: some View {
        Section {
            ForEach(GameSettings.ImposterIntel.allCases, id: \.self) { option in
                Button {
                    intel = option
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Image(systemName: intel == option ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(intel == option ? Color.crewInk : Color.haze)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.title)
                                .foregroundStyle(Color.cardStock)
                            Text(option.detail)
                                .font(.footnote)
                                .foregroundStyle(Color.haze)
                        }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(intel == option ? .isSelected : [])
            }
        } header: {
            SectionTitle("What the imposter sees")
        }
        .listRowBackground(Color.feltRaised)
    }
}

// MARK: - Rounds and timers

private struct RoundsSection: View {
    @Binding var settings: GameSettings

    var body: some View {
        Section {
            Stepper(value: $settings.clueRounds, in: 1...5) {
                Text(settings.clueRounds == 1 ? "Clues go around once" : "Clues go around \(settings.clueRounds) times")
                    .foregroundStyle(Color.cardStock)
            }
            Picker("Time per clue", selection: $settings.turnSeconds) {
                Text("No timer").tag(Int?.none)
                ForEach([10, 20, 30, 45], id: \.self) { seconds in
                    Text("\(seconds) seconds").tag(Int?.some(seconds))
                }
            }
            Picker("Time to discuss", selection: $settings.discussionSeconds) {
                Text("No timer").tag(Int?.none)
                ForEach([60, 120, 180, 300], id: \.self) { seconds in
                    Text(seconds == 60 ? "1 minute" : "\(seconds / 60) minutes").tag(Int?.some(seconds))
                }
            }
        } header: {
            SectionTitle("Rounds")
        }
        .foregroundStyle(Color.cardStock)
        .listRowBackground(Color.feltRaised)
    }
}

private struct HouseRulesSection: View {
    @Binding var settings: GameSettings

    var body: some View {
        Section {
            Toggle(isOn: $settings.lastChanceGuess) {
                RuleLabel("Last-chance guess", detail: "A caught imposter can still win by guessing the word.")
            }
            Toggle(isOn: $settings.imposterMayStart) {
                RuleLabel("Imposter can go first", detail: "Otherwise the first clue always comes from the crew.")
            }
            Picker(selection: $settings.trollChance) {
                ForEach(TrollFrequency.allCases, id: \.self) { frequency in
                    Text(frequency.title).tag(frequency.chance)
                }
            } label: {
                RuleLabel("Troll rounds", detail: "Now and then, everyone is secretly the imposter.")
            }
        } header: {
            SectionTitle("House rules")
        }
        .tint(Color.crewInk)
        .listRowBackground(Color.feltRaised)
    }
}

private enum TrollFrequency: CaseIterable {
    case never, rare, sometimes, often

    var title: String {
        switch self {
        case .never: "Never"
        case .rare: "Rarely"
        case .sometimes: "Sometimes"
        case .often: "Often"
        }
    }

    var chance: Double {
        switch self {
        case .never: 0
        case .rare: 0.05
        case .sometimes: 0.15
        case .often: 0.3
        }
    }
}

// MARK: - Shared pieces

private struct SectionTitle: View {
    var title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.displaySemiBold(20, relativeTo: .title3))
            .foregroundStyle(Color.cardStock)
            .textCase(nil)
    }
}

private struct RuleLabel: View {
    var title: String
    var detail: String

    init(_ title: String, detail: String) {
        self.title = title
        self.detail = detail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .foregroundStyle(Color.cardStock)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(Color.haze)
        }
    }
}

extension WordCard.Difficulty {
    var title: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        }
    }
}

extension GameSettings.ImposterIntel {
    var title: String {
        switch self {
        case .nothing: "Nothing"
        case .hint: "A hint word"
        case .decoy: "A similar word"
        }
    }

    var detail: String {
        switch self {
        case .nothing: "Their card just says Imposter. The classic way to play."
        case .hint: "A related word to help them bluff. Good for younger players."
        case .decoy: "A close cousin of the secret word. They won't know they're the imposter."
        }
    }
}

#Preview {
    let library = WordLibrary.bundledOrEmpty()
    let roster = RosterStore(defaults: UserDefaults(suiteName: "preview-rules")!)
    for name in ["Ryu", "Aiko", "Ben", "Chloe", "Dev"] {
        try? roster.add(name)
    }
    return NavigationStack {
        RulesView {}
    }
    .environment(\.wordLibrary, library)
    .environment(roster)
    .environment(RulesStore(library: library, defaults: UserDefaults(suiteName: "preview-rules")!))
    .environment(GameStore(defaults: UserDefaults(suiteName: "preview-rules")!))
}

import ImposterKit
import SwiftUI

/// The optional twists: last-chance guess, who starts, and troll rounds.
struct HouseRulesSection: View {
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

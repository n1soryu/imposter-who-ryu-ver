import ImposterKit
import SwiftUI

/// How many imposters, capped so the crew stays a majority.
struct ImpostersSection: View {
    @Binding var settings: GameSettings
    var playerCount: Int

    var body: some View {
        let maximum = GameSettings.maximumImposters(forPlayers: playerCount)

        Section {
            Stepper(value: $settings.imposterCount, in: 1...maximum) {
                Text("^[\(settings.imposterCount) imposter](inflect: true)")
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

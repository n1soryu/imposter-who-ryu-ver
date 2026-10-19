import ImposterKit
import SwiftUI

/// What the imposter's card shows: nothing, a hint, or a decoy word.
struct ImposterIntelSection: View {
    @Binding var intel: GameSettings.ImposterIntel

    var body: some View {
        Section {
            ForEach(GameSettings.ImposterIntel.allCases, id: \.self) { option in
                IntelOptionRow(option: option, isSelected: intel == option) {
                    intel = option
                }
            }
        } header: {
            SectionTitle("What the imposter sees")
        }
        .listRowBackground(Color.feltRaised)
    }
}

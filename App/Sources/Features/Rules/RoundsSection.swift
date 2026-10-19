import ImposterKit
import SwiftUI

/// How many times clues go around, plus the turn and discussion timers.
struct RoundsSection: View {
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
                ForEach([1, 2, 3, 5], id: \.self) { minutes in
                    Text("^[\(minutes) minute](inflect: true)").tag(Int?.some(minutes * 60))
                }
            }
        } header: {
            SectionTitle("Rounds")
        }
        .foregroundStyle(Color.cardStock)
        .listRowBackground(Color.feltRaised)
    }
}

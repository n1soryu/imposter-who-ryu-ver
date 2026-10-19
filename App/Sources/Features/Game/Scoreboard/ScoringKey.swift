import ImposterKit
import SwiftUI

/// A short explanation of how points are earned.
struct ScoringKey: View {
    var rules: ScoringRules

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("How points work")
                .font(.headline)
                .foregroundStyle(Color.cardStock)
            Group {
                Text("Crew catch an imposter: +\(rules.crewWin) each, +\(rules.correctVote) more for voting for them in secret.")
                Text("Imposters get away or guess the word: +\(rules.imposterWin) each.")
                Text("Troll rounds: no points.")
            }
            .font(.subheadline)
            .foregroundStyle(Color.haze)
        }
    }
}

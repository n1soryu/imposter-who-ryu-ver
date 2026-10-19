import ImposterKit
import SwiftUI

/// Standings across every round played tonight.
struct ScoreboardView: View {
    var session: GameSession

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let standings = Standings(session: session)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("After ^[\(session.scoreboard.roundsPlayed) round](inflect: true).")
                        .foregroundStyle(Color.haze)
                        .padding(.bottom, 12)

                    ForEach(standings.entries, id: \.player.id) { entry in
                        StandingRow(place: entry.place, name: entry.player.name, points: entry.points, isLeader: entry.isLeader)
                    }

                    ScoringKey(rules: session.scoreboard.rules)
                        .padding(.top, 24)
                }
                .padding(Metrics.gutter)
            }
            .background(Color.felt)
            .navigationTitle("Scoreboard")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
}

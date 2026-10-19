import ImposterKit
import SwiftUI

/// Standings across every round played tonight.
struct ScoreboardView: View {
    var session: GameSession

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let standings = session.scoreboard.standings(for: session.players)
        let leaders = Set(standings.filter { $0.points == standings.first?.points && $0.points > 0 }.map(\.player.id))

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(roundsPlayedText)
                        .foregroundStyle(Color.haze)
                        .padding(.bottom, 12)

                    ForEach(Array(standings.enumerated()), id: \.element.player.id) { place, entry in
                        StandingRow(
                            place: rank(of: place, in: standings),
                            name: entry.player.name,
                            points: entry.points,
                            isLeader: leaders.contains(entry.player.id)
                        )
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
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var roundsPlayedText: String {
        let rounds = session.scoreboard.roundsPlayed
        return rounds == 1 ? "After 1 round." : "After \(rounds) rounds."
    }

    /// Players on the same points share a place, like 1, 2, 2, 4.
    private func rank(of index: Int, in standings: [(player: Player, points: Int)]) -> Int {
        let points = standings[index].points
        return (standings.firstIndex { $0.points == points } ?? index) + 1
    }
}

private struct StandingRow: View {
    var place: Int
    var name: String
    var points: Int
    var isLeader: Bool

    var body: some View {
        HStack(spacing: 16) {
            Text("\(place)")
                .font(.displaySemiBold(20, relativeTo: .title3))
                .monospacedDigit()
                .frame(minWidth: 24, alignment: .trailing)
                .foregroundStyle(isLeader ? Color.felt : Color.haze)
            Text(name)
                .font(.displaySemiBold(22, relativeTo: .title3))
            Spacer()
            Text("\(points)")
                .font(.display(28, relativeTo: .title2))
                .monospacedDigit()
        }
        .foregroundStyle(isLeader ? Color.felt : Color.cardStock)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(isLeader ? Color.crewInk : Color.feltRaised, in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Place \(place), \(name), \(points) \(points == 1 ? "point" : "points")\(isLeader ? ", leading" : "")")
    }
}

private struct ScoringKey: View {
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

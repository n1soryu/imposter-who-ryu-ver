import ImposterKit
import SwiftUI

/// The vote breakdown, undercover decoys and points from the round.
struct RoundFacts: View {
    var round: Round
    var result: GameSession.RoundResult

    var body: some View {
        let facts = RoundFactsModel(round: round, result: result)

        VStack(alignment: .leading, spacing: 20) {
            if facts.decoys.isEmpty == false {
                FactGroup(title: "Undercover") {
                    ForEach(facts.decoys, id: \.player.id) { entry in
                        Text("\(entry.player.name) had \(entry.decoy)")
                    }
                }
            }

            if facts.votes.isEmpty == false {
                FactGroup(title: "Votes") {
                    ForEach(facts.votes, id: \.player.id) { entry in
                        HStack {
                            Text(entry.player.name)
                            Spacer()
                            Text("^[\(entry.count) vote](inflect: true)")
                                .foregroundStyle(Color.haze)
                        }
                    }
                }
            }

            FactGroup(title: "Points this round") {
                if facts.points.isEmpty {
                    Text("Nobody scores in a troll round.")
                        .foregroundStyle(Color.haze)
                }
                ForEach(facts.points, id: \.player.id) { entry in
                    HStack {
                        Text(entry.player.name)
                        Spacer()
                        Text("+\(entry.points)")
                            .font(.displaySemiBold(18, relativeTo: .body))
                            .foregroundStyle(Color.crewInk)
                    }
                }
            }
        }
        .foregroundStyle(Color.cardStock)
    }
}

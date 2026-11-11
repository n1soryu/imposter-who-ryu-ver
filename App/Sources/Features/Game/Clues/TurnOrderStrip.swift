import ImposterKit
import SwiftUI

/// The speaking order this lap. Players who've gone are dimmed and the current speaker is highlighted.
struct TurnOrderStrip: View {
    var players: [Player]
    var currentTurn: Int

    init(round: Round, currentTurn: Int) {
        players = round.turnOrder.compactMap(round.player)
        self.currentTurn = currentTurn
    }

    init(players: [Player], currentTurn: Int) {
        self.players = players
        self.currentTurn = currentTurn
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                        Text(player.name)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(index == currentTurn ? Color.felt : Color.cardStock)
                            .background(index == currentTurn ? Color.crewInk : Color.feltRaised, in: .capsule)
                            .opacity(index < currentTurn ? 0.4 : 1)
                            .id(player.id)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .onChange(of: currentTurn, initial: true) { _, turn in
                withAnimation { proxy.scrollTo(players[turn].id, anchor: .center) }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Turn \(currentTurn + 1) of \(players.count)")
    }
}

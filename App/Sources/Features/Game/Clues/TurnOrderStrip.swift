import ImposterKit
import SwiftUI

/// The speaking order this lap. Players who've gone are dimmed and the current speaker is highlighted.
struct TurnOrderStrip: View {
    var round: Round
    var currentTurn: Int

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Array(round.turnOrder.enumerated()), id: \.element) { index, id in
                        Text(round.player(id)?.name ?? "")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(index == currentTurn ? Color.felt : Color.cardStock)
                            .background(index == currentTurn ? Color.crewInk : Color.feltRaised, in: .capsule)
                            .opacity(index < currentTurn ? 0.4 : 1)
                            .id(id)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .onChange(of: currentTurn, initial: true) { _, turn in
                withAnimation { proxy.scrollTo(round.turnOrder[turn], anchor: .center) }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Turn \(currentTurn + 1) of \(round.turnOrder.count)")
    }
}

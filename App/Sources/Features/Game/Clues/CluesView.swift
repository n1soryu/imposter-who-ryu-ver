import ImposterKit
import SwiftUI

/// One clue turn: who's speaking, the order around the table, and an optional timer.
struct CluesView: View {
    var round: Round
    var lap: Int
    var turn: Int
    var next: () -> Void
    var skipToDiscussion: () -> Void

    var body: some View {
        let isLastTurn = lap == round.settings.clueRounds && turn == round.turnOrder.count - 1

        VStack(alignment: .leading, spacing: 0) {
            Text(round.settings.clueRounds == 1 ? "Clues" : "Clues, lap \(lap) of \(round.settings.clueRounds)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.haze)

            Spacer(minLength: 16)

            Text(round.player(round.turnOrder[turn])?.name ?? "")
                .font(.display(64))
                .foregroundStyle(Color.cardStock)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
            Text("Give a one-word clue about the secret word.")
                .font(.title3)
                .foregroundStyle(Color.haze)
                .padding(.top, 4)

            if let seconds = round.settings.turnSeconds {
                Countdown(seconds: seconds)
                    .id("\(lap)-\(turn)")
                    .padding(.top, 24)
            }

            Spacer(minLength: 16)

            TurnOrderStrip(round: round, currentTurn: turn)
                .padding(.bottom, 24)

            VStack(spacing: 12) {
                Button(isLastTurn ? "Start the discussion" : "Next player", action: next)
                    .buttonStyle(.pill)
                Button("Skip to discussion", action: skipToDiscussion)
                    .buttonStyle(.pillSecondary)
                    .opacity(isLastTurn ? 0 : 1)
                    .disabled(isLastTurn)
            }
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.felt)
        .sensoryFeedback(.selection, trigger: turn)
    }
}

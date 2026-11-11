import ImposterKit
import SwiftUI

/// One clue turn: who's speaking, the order around the table, a timer and the host's controls.
struct HostCluesView: View {
    var lap: Int
    var laps: Int
    var turnOrder: [Player]
    var currentTurn: Int
    var secondsLeft: Int?
    var hostIsUp: Bool
    var next: () -> Void
    var skipToDiscussion: () -> Void

    var body: some View {
        let isLastTurn = lap == laps && currentTurn == turnOrder.count - 1
        let speaker = turnOrder[currentTurn]

        AdaptiveScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(laps == 1 ? "Clues" : "Clues, lap \(lap) of \(laps)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.haze)

                Spacer(minLength: 16)

                Text(hostIsUp ? "Your turn" : speaker.name)
                    .font(.display(64))
                    .foregroundStyle(hostIsUp ? Color.crewInk : Color.cardStock)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                Text("Give a one-word clue about the secret word.")
                    .font(.title3)
                    .foregroundStyle(Color.haze)
                    .padding(.top, 4)

                if let secondsLeft {
                    Countdown(seconds: secondsLeft)
                        .id("\(lap)-\(currentTurn)")
                        .padding(.top, 24)
                }

                Spacer(minLength: 16)

                TurnOrderStrip(players: turnOrder, currentTurn: currentTurn)
                    .padding(.bottom, 24)

                VStack(spacing: 12) {
                    if hostIsUp {
                        Button(isLastTurn ? "Done, start the discussion" : "Done with my clue", action: next)
                            .buttonStyle(.pill)
                    } else {
                        Button(isLastTurn ? "Start the discussion" : "Next clue", action: next)
                            .buttonStyle(.pillSecondary)
                    }
                    if isLastTurn == false {
                        Button("Skip to discussion", action: skipToDiscussion)
                            .buttonStyle(.pillSecondary)
                    }
                }
            }
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.felt)
        .sensoryFeedback(hostIsUp ? .success : .selection, trigger: currentTurn)
    }
}

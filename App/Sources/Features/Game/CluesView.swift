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
        let speaker = round.player(round.turnOrder[turn])

        VStack(alignment: .leading, spacing: 0) {
            Text(lapTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.haze)

            Spacer(minLength: 16)

            Text(speaker?.name ?? "")
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

            TurnOrder(round: round, currentTurn: turn)
                .padding(.bottom, 24)

            VStack(spacing: 12) {
                Button(isLastTurn ? "Start the discussion" : "Next player", action: next)
                    .buttonStyle(.pill)
                if isLastTurn == false {
                    Button("Skip to discussion", action: skipToDiscussion)
                        .buttonStyle(.pillSecondary)
                }
            }
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.felt)
        .sensoryFeedback(.selection, trigger: turn)
    }

    private var lapTitle: String {
        let laps = round.settings.clueRounds
        return laps == 1 ? "Clues" : "Clues, lap \(lap) of \(laps)"
    }

    private var isLastTurn: Bool {
        lap == round.settings.clueRounds && turn == round.turnOrder.count - 1
    }
}

/// The speaking order this lap. Players who've gone are dimmed and the current speaker is highlighted.
private struct TurnOrder: View {
    var round: Round
    var currentTurn: Int

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Array(round.turnOrder.enumerated()), id: \.element) { index, id in
                        let isCurrent = index == currentTurn
                        Text(round.player(id)?.name ?? "")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(isCurrent ? Color.felt : Color.cardStock)
                            .background(isCurrent ? Color.crewInk : Color.feltRaised, in: .capsule)
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

/// Talk it over before voting.
struct DiscussionView: View {
    var seconds: Int?
    var startVoting: () -> Void
    var quickVote: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("Who's the imposter?")
                .font(.display(56))
                .foregroundStyle(Color.cardStock)
                .minimumScaleFactor(0.5)
            Text("Talk it over. Who hesitated? Whose clue didn't quite fit?")
                .font(.title3)
                .foregroundStyle(Color.haze)
                .padding(.top, 8)

            if let seconds {
                Countdown(seconds: seconds)
                    .padding(.top, 24)
            }

            Spacer()

            VStack(spacing: 12) {
                Button("Vote in secret", action: startVoting)
                    .buttonStyle(.pill)
                Button("We've agreed on someone", action: quickVote)
                    .buttonStyle(.pillSecondary)
            }
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.felt)
    }
}

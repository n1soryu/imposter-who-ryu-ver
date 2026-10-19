import ImposterKit
import SwiftUI

/// The reveal: who the imposter was, what the word was, and who won.
struct ResultsView: View {
    var session: GameSession
    var result: GameSession.RoundResult
    var nextRound: () -> Void
    var showScoreboard: () -> Void

    @State private var isRevealed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let summary = ResultSummary(round: session.round, result: result)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(summary.headline)
                    .font(.display(48))
                    .foregroundStyle(summary.isCrewWin ? Color.crewInk : Color.imposterInk)
                    .minimumScaleFactor(0.5)
                Text(summary.detail)
                    .font(.title3)
                    .foregroundStyle(Color.cardStock)
                    .padding(.top, 6)

                RevealedCards(round: session.round, symbol: session.categorySymbol, isRevealed: isRevealed)
                    .frame(height: 280)
                    .padding(.vertical, 28)

                RoundFacts(round: session.round, result: result)
            }
            .padding(Metrics.gutter)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.felt)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button("Next round", action: nextRound)
                    .buttonStyle(.pill)
                Button("Scoreboard", action: showScoreboard)
                    .buttonStyle(.pillSecondary)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 12)
            .background(Color.felt)
        }
        .sensoryFeedback(summary.isCrewWin ? .success : .warning, trigger: isRevealed)
        .task(revealCards)
    }

    /// The one staged moment in the app: the imposter's card turns over a beat after the screen appears.
    private func revealCards() async {
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 450))
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.6, bounce: 0.35)) {
            isRevealed = true
        }
    }
}

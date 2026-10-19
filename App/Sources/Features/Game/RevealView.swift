import ImposterKit
import SwiftUI

/// The caught imposter gets one guess at the secret word.
struct LastChanceView: View {
    var imposter: Player
    var guess: (String?) -> Void

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Caught!")
                .font(.display(64))
                .foregroundStyle(Color.imposterInk)
            Text("\(imposter.name) was the imposter. They get one last chance: guess the word to steal the win.")
                .font(.title3)
                .foregroundStyle(Color.cardStock)
                .padding(.top, 8)

            TextField("Their guess", text: $text)
                .font(.displaySemiBold(26, relativeTo: .title2))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isFocused)
                .onSubmit(submit)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.feltRaised, in: .rect(cornerRadius: 18))
                .padding(.top, 32)

            Spacer()

            VStack(spacing: 12) {
                Button("Lock in the guess", action: submit)
                    .buttonStyle(.pill)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("\(imposter.name) gives up") { guess(nil) }
                    .buttonStyle(.pillSecondary)
            }
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.felt)
        .onAppear { isFocused = true }
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty == false else { return }
        guess(trimmed)
    }
}

/// The reveal: who the imposter was, what the word was, and who won.
struct ResultsView: View {
    var session: GameSession
    var result: GameSession.RoundResult
    var nextRound: () -> Void
    var showScoreboard: () -> Void

    @State private var isRevealed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let round = session.round
        let summary = ResultSummary(round: round, result: result)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(summary.headline)
                    .font(.display(48))
                    .foregroundStyle(summary.headlineInk)
                    .minimumScaleFactor(0.5)
                Text(summary.detail)
                    .font(.title3)
                    .foregroundStyle(Color.cardStock)
                    .padding(.top, 6)

                RevealedCards(round: round, symbol: session.categorySymbol, isRevealed: isRevealed)
                    .frame(height: 280)
                    .padding(.vertical, 28)

                RoundFacts(round: round, result: result)
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
        .sensoryFeedback(result.outcome.crewWon ? .success : .warning, trigger: isRevealed)
        .task {
            // The one staged moment in the app: the imposter's card turns over a beat after the screen appears.
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 450))
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.6, bounce: 0.35)) {
                isRevealed = true
            }
        }
    }
}

/// The secret word card and the imposter's card, which flips over and slides out from behind it.
private struct RevealedCards: View {
    var round: Round
    var symbol: String
    var isRevealed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let imposterNames = round.players.filter { round.isImposter($0.id) }.map(\.name)

        ZStack {
            CrewCard(word: round.card.word, symbol: symbol)
                .rotationEffect(.degrees(isRevealed ? -8 : 0))
                .offset(x: isRevealed ? -62 : 0)
            PlayingCard(face: .imposterInk, misprint: .crewInk, cornerMark: "?") {
                VStack(spacing: 8) {
                    Text(imposterNames.count == 1 ? "Imposter" : "Imposters")
                        .font(.subheadline.weight(.semibold))
                    Text(ListFormatter.localizedString(byJoining: imposterNames))
                        .font(.display(34))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.4)
                }
                .foregroundStyle(Color.felt)
            }
            .rotationEffect(.degrees(isRevealed ? 9 : 0))
            .rotation3DEffect(.degrees(isRevealed || reduceMotion ? 0 : 90), axis: (x: 0, y: 1, z: 0))
            .offset(x: isRevealed ? 62 : 0, y: isRevealed ? 10 : 0)
            .opacity(isRevealed ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The word was \(round.card.word). \(ListFormatter.localizedString(byJoining: imposterNames)) \(imposterNames.count == 1 ? "was the imposter" : "were the imposters").")
    }
}

/// The vote breakdown, undercover decoys and points from the round.
private struct RoundFacts: View {
    var round: Round
    var result: GameSession.RoundResult

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            let decoys = round.players.compactMap { player -> String? in
                guard case .undercover(let decoy) = round.role(of: player.id) else { return nil }
                return "\(player.name) had \(decoy)"
            }
            if decoys.isEmpty == false {
                FactGroup(title: "Undercover") {
                    ForEach(decoys, id: \.self) { Text($0) }
                }
            }

            if let tally = result.tally {
                FactGroup(title: "Votes") {
                    ForEach(round.players.filter { tally.counts[$0.id] != nil }.sorted { tally.counts[$0.id, default: 0] > tally.counts[$1.id, default: 0] }) { player in
                        let count = tally.counts[player.id, default: 0]
                        HStack {
                            Text(player.name)
                            Spacer()
                            Text(count == 1 ? "1 vote" : "\(count) votes")
                                .foregroundStyle(Color.haze)
                        }
                    }
                }
            }

            FactGroup(title: "Points this round") {
                if result.awards.isEmpty {
                    Text("Nobody scores in a troll round.")
                        .foregroundStyle(Color.haze)
                } else {
                    ForEach(round.players.filter { result.awards[$0.id] != nil }) { player in
                        HStack {
                            Text(player.name)
                            Spacer()
                            Text("+\(result.awards[player.id, default: 0])")
                                .font(.displaySemiBold(18, relativeTo: .body))
                                .foregroundStyle(Color.crewInk)
                        }
                    }
                }
            }
        }
        .foregroundStyle(Color.cardStock)
    }
}

private struct FactGroup<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.displaySemiBold(20, relativeTo: .title3))
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.feltRaised, in: .rect(cornerRadius: 18))
        }
    }
}

/// Headline copy for each way a round can end.
struct ResultSummary {
    var headline: String
    var detail: String
    var headlineInk: Color

    init(round: Round, result: GameSession.RoundResult) {
        let name = { (id: Player.ID?) in id.flatMap { round.player($0)?.name } ?? "Someone" }

        switch result.outcome {
        case .crewWins(let caught):
            headline = "The crew wins"
            detail = "\(name(caught)) was caught."
            headlineInk = .crewInk
        case .imposterStoleWin(let caught, let guess):
            headline = "\(name(caught)) stole it"
            detail = "Caught, but they guessed \"\(guess)\". Imposters win."
            headlineInk = .imposterInk
        case .impostersWin(let accused?):
            headline = "Wrong person"
            detail = "\(name(accused)) was innocent. Imposters win."
            headlineInk = .imposterInk
        case .impostersWin(nil):
            headline = "Nobody was accused"
            detail = "The vote was split, so the imposters get away with it."
            headlineInk = .imposterInk
        case .trollRound:
            headline = "Troll round"
            detail = "Everyone was the imposter. Nobody had the word."
            headlineInk = .imposterInk
        }
    }
}

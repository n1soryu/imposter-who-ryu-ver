import ImposterHost
import ImposterKit
import SwiftUI

/// The host's screen for whichever phase the hosted round is in, wired to the host's controls.
struct HostPhaseView: View {
    var controller: HostController
    var showScoreboard: () -> Void
    var backToLobby: () -> Void

    @Environment(HostStore.self) private var host
    @State private var peeked: PeekedCard?
    @State private var peekProblem: String?
    @State private var isQuickVoting = false

    var body: some View {
        let view = controller.hostView

        content(for: view)
            .safeAreaInset(edge: .top, spacing: 0) {
                if view.disconnectedBlockers.isEmpty == false {
                    WaitingBanner(names: view.disconnectedBlockers)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if allowsPeek(view.phase) {
                    peekButton(peeksLeft: view.peeksLeft)
                }
            }
            .sheet(item: $peeked) { card in
                PeekSheet(face: card.face, categorySymbol: controller.session.game?.categorySymbol ?? "?", peeksLeft: card.peeksLeft)
            }
            .alert("Can't peek", isPresented: peekProblemShown) {
            } message: {
                Text(peekProblem ?? "")
            }
    }

    @ViewBuilder
    private func content(for view: PlayerView) -> some View {
        switch view.phase {
        case .join, .lobby:
            Color.felt.onAppear(perform: backToLobby)

        case .dealing(let categoryName, let symbol, let face, _, let waitingFor):
            HostDealView(
                categoryName: categoryName,
                categorySymbol: symbol,
                face: face,
                players: view.players,
                waitingFor: waitingFor,
                done: controller.cardSeen
            )
            .id(view.roundNumber)

        case .clues(let lap, let laps, let turnOrder, let current, let secondsLeft):
            let order = turnOrder.compactMap { id in view.roomPlayers.first { $0.id == id } }
            if let turn = order.firstIndex(where: { $0.id == current }) {
                HostCluesView(
                    lap: lap,
                    laps: laps,
                    turnOrder: order,
                    currentTurn: turn,
                    secondsLeft: secondsLeft,
                    hostIsUp: current == controller.hostPlayerID,
                    next: controller.clueDone,
                    skipToDiscussion: controller.endClues
                )
            }

        case .discussion(let secondsLeft):
            DiscussionView(seconds: secondsLeft, startVoting: controller.startVoting) {
                isQuickVoting = true
            }
            .sheet(isPresented: $isQuickVoting) {
                QuickAccuseView(players: controller.session.game?.round.players ?? view.roomPlayers) { accused in
                    controller.quickAccuse(accused)
                }
            }

        case .voting(let voted, let youVoted):
            HostVotingView(
                hostID: controller.hostPlayerID,
                players: view.players,
                voted: voted,
                youVoted: youVoted,
                cast: controller.vote,
                reveal: controller.revealVotes
            )

        case .lastChance(let accused, let youAreAccused):
            if youAreAccused {
                LastChanceView(imposterName: view.name(of: accused), isYou: true) { guess in
                    controller.guess(guess)
                }
            } else {
                HostLastChanceWaitView(accusedName: view.name(of: accused))
            }

        case .finished:
            if let game = controller.session.game, case .finished(let result) = game.phase {
                ResultsView(
                    session: game,
                    result: result,
                    nextRound: host.nextRound,
                    showScoreboard: showScoreboard,
                    endGame: controller.endGame
                )
                .id(view.roundNumber)
            }
        }
    }

    private func allowsPeek(_ phase: PlayerView.Phase) -> Bool {
        switch phase {
        case .clues, .discussion, .voting, .lastChance: true
        case .join, .lobby, .dealing, .finished: false
        }
    }

    private func peekButton(peeksLeft: Int) -> some View {
        Button(action: peek) {
            Label(peeksLeft > 0 ? "See my card (\(peeksLeft) left)" : "No peeks left", systemImage: "eye")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .foregroundStyle(Color.haze)
        .disabled(peeksLeft == 0)
        .background(Color.felt)
    }

    private func peek() {
        do {
            let face = try controller.peek()
            peeked = PeekedCard(face: face, peeksLeft: controller.hostView.peeksLeft)
        } catch {
            peekProblem = error.message
        }
    }

    private var peekProblemShown: Binding<Bool> {
        Binding(get: { peekProblem != nil }, set: { if $0 == false { peekProblem = nil } })
    }
}

/// Tells the host the game can't move on because someone's phone is offline.
private struct WaitingBanner: View {
    var names: [String]

    var body: some View {
        Label("Waiting for \(names.formatted()) to reconnect", systemImage: "wifi.exclamationmark")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.cardStock)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 10)
            .background(Color.feltRaised)
            .accessibilityElement(children: .combine)
    }
}

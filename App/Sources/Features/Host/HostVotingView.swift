import ImposterKit
import SwiftUI

/// The host's own secret ballot, then who has voted so far.
struct HostVotingView: View {
    var hostID: Player.ID
    var players: [PlayerView.Participant]
    var voted: [Player.ID]
    var youVoted: Bool
    var cast: (Player.ID) -> Void
    var reveal: () -> Void

    @State private var suspect: Player.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if youVoted {
                Text("Your vote is in")
                    .font(.display(44))
                    .foregroundStyle(Color.cardStock)
                    .minimumScaleFactor(0.5)
                Text("^[\(voted.count) of \(players.count) vote](inflect: true) so far. Nobody sees who you picked.")
                    .foregroundStyle(Color.haze)
                    .padding(.top, 4)
                ScrollView {
                    HostStatusList(players: players, readyLabel: "Voted", pending: pendingVoters)
                }
                .scrollBounceBehavior(.basedOnSize)
                .padding(.vertical, 20)
            } else {
                Text("Who's the imposter?")
                    .font(.display(40))
                    .foregroundStyle(Color.cardStock)
                    .minimumScaleFactor(0.5)
                Text("Nobody will see who you picked.")
                    .foregroundStyle(Color.haze)
                    .padding(.top, 4)
                SuspectPicker(players: candidates, selection: $suspect)
                    .padding(.vertical, 20)
                Button(voteLabel, action: submit)
                    .buttonStyle(.pill)
                    .disabled(suspect == nil)
                    .padding(.bottom, 12)
            }
            Button("Reveal votes now", action: reveal)
                .buttonStyle(.pillSecondary)
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.felt)
        .sensoryFeedback(.success, trigger: youVoted) { _, voted in voted }
    }

    private var pendingVoters: [Player.ID] {
        players.map(\.id).filter { voted.contains($0) == false }
    }

    private var candidates: [Player] {
        players.filter { $0.id != hostID }.map { Player(id: $0.id, name: $0.name) }
    }

    private var voteLabel: String {
        guard let name = players.first(where: { $0.id == suspect })?.name else { return "Pick someone" }
        return "Vote for \(name)"
    }

    private func submit() {
        if let suspect { cast(suspect) }
    }
}

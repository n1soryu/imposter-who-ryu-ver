import ImposterKit
import SwiftUI

/// Secret ballots: the phone goes around, each player votes in private, then the result is revealed.
struct VotingView: View {
    var round: Round
    /// Who should vote next, or `nil` once everyone has voted.
    var voter: Player?
    var votesCast: Int
    var cast: (_ voter: Player.ID, _ suspect: Player.ID) -> Void
    var reveal: () -> Void

    var body: some View {
        Group {
            if let voter {
                BallotTurn(round: round, voter: voter, votesCast: votesCast) { suspect in
                    cast(voter.id, suspect)
                }
                .id(voter.id)
            } else {
                AllVotesIn(count: votesCast, reveal: reveal)
            }
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.felt)
    }
}

private struct BallotTurn: View {
    var round: Round
    var voter: Player
    var votesCast: Int
    var lockIn: (Player.ID) -> Void

    @State private var isHoldingPhone = false
    @State private var suspect: Player.ID?

    var body: some View {
        if isHoldingPhone {
            VStack(alignment: .leading, spacing: 0) {
                Text("Who's the imposter, \(voter.name)?")
                    .font(.display(40))
                    .foregroundStyle(Color.cardStock)
                    .minimumScaleFactor(0.5)
                Text("Nobody will see who you picked.")
                    .foregroundStyle(Color.haze)
                    .padding(.top, 4)

                SuspectPicker(players: round.players.filter { $0.id != voter.id }, selection: $suspect)
                    .padding(.vertical, 20)

                Button(suspect.flatMap { round.player($0)?.name }.map { "Vote for \($0)" } ?? "Pick someone") {
                    if let suspect { lockIn(suspect) }
                }
                .buttonStyle(.pill)
                .disabled(suspect == nil)
            }
            .transition(.opacity)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("Vote \(votesCast + 1) of \(round.players.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.haze)
                Spacer()
                Text("Pass the phone to")
                    .font(.title3)
                    .foregroundStyle(Color.haze)
                Text(voter.name)
                    .font(.display(64))
                    .foregroundStyle(Color.cardStock)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                Spacer()
                Button("I'm \(voter.name)") {
                    withAnimation(.snappy) { isHoldingPhone = true }
                }
                .buttonStyle(.pill)
            }
            .transition(.opacity)
        }
    }
}

private struct AllVotesIn: View {
    var count: Int
    var reveal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("All \(count) votes are in")
                .font(.display(56))
                .foregroundStyle(Color.cardStock)
                .minimumScaleFactor(0.5)
            Text("Put the phone where everyone can see it.")
                .font(.title3)
                .foregroundStyle(Color.haze)
                .padding(.top, 8)
            Spacer()
            Button("Reveal the vote", action: reveal)
                .buttonStyle(.pill)
        }
    }
}

/// A scrolling list of players to accuse. Tapping one selects it.
struct SuspectPicker: View {
    var players: [Player]
    @Binding var selection: Player.ID?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(players) { player in
                    let isSelected = selection == player.id
                    Button {
                        selection = player.id
                    } label: {
                        HStack {
                            Text(player.name)
                                .font(.displaySemiBold(22, relativeTo: .title3))
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.headline)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .foregroundStyle(isSelected ? Color.felt : Color.cardStock)
                        .background(isSelected ? Color.crewInk : Color.feltRaised, in: .rect(cornerRadius: 18))
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// The group agreed out loud: pick who they're accusing, or say they couldn't agree.
struct QuickAccuseView: View {
    var players: [Player]
    var accuse: (Player.ID?) -> Void

    @State private var suspect: Player.ID?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Pick the player you're accusing.")
                    .foregroundStyle(Color.haze)
                SuspectPicker(players: players, selection: $suspect)
                    .padding(.vertical, 20)
                VStack(spacing: 12) {
                    Button(suspect.flatMap { id in players.first { $0.id == id }?.name }.map { "Accuse \($0)" } ?? "Pick someone") {
                        accuse(suspect)
                        dismiss()
                    }
                    .buttonStyle(.pill)
                    .disabled(suspect == nil)
                    Button("We couldn't agree") {
                        accuse(nil)
                        dismiss()
                    }
                    .buttonStyle(.pillSecondary)
                }
            }
            .padding(Metrics.gutter)
            .background(Color.felt)
            .navigationTitle("Who did it?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

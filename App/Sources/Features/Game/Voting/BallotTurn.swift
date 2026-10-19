import ImposterKit
import SwiftUI

/// One voter's turn: the hand-off, then a private ballot that leaves out their own name.
struct BallotTurn: View {
    var voter: Player
    var candidates: [Player]
    var progress: String
    var lockIn: (Player.ID) -> Void

    @State private var isHoldingPhone = false
    @State private var suspect: Player.ID?

    var body: some View {
        Group {
            if isHoldingPhone {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Who's the imposter, \(voter.name)?")
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
                }
            } else {
                PassThePhoneView(name: voter.name, progress: progress, confirm: takePhone)
            }
        }
        .transition(.opacity)
    }

    private var voteLabel: String {
        guard let name = candidates.first(where: { $0.id == suspect })?.name else { return "Pick someone" }
        return "Vote for \(name)"
    }

    private func takePhone() {
        withAnimation(.snappy) { isHoldingPhone = true }
    }

    private func submit() {
        if let suspect { lockIn(suspect) }
    }
}

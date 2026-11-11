import ImposterKit
import SwiftUI

/// Everyone at the table with a connection dot, and a mark for those who are done with the current step.
struct HostStatusList: View {
    var players: [PlayerView.Participant]
    /// Shown next to players who aren't in `pending`, such as "Voted".
    var readyLabel: String
    var pending: [Player.ID]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(players, id: \.id) { player in
                HostPlayerRow(
                    name: player.name,
                    isHost: player.isHost,
                    isConnected: player.isConnected,
                    mark: pending.contains(player.id) ? nil : readyLabel,
                    remove: nil
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                if player.id != players.last?.id {
                    Divider().overlay(Color.felt)
                }
            }
        }
        .background(Color.feltRaised, in: .rect(cornerRadius: 18))
    }
}

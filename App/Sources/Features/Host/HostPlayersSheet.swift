import ImposterHost
import SwiftUI

/// Who is at the table and whose phone is connected. Players can be removed between rounds.
struct HostPlayersSheet: View {
    var controller: HostController

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let view = controller.hostView
        let canRemove = if case .finished = view.phase { true } else { false }

        NavigationStack {
            List {
                Section {
                    ForEach(view.players, id: \.id) { player in
                        HostPlayerRow(
                            name: player.name,
                            isHost: player.isHost,
                            isConnected: player.isConnected,
                            mark: nil,
                            remove: canRemove && player.isHost == false ? { controller.kick(player.id) } : nil
                        )
                    }
                    .listRowBackground(Color.feltRaised)
                } footer: {
                    Text(canRemove
                         ? "Friends can still join until you deal the next round."
                         : "Players can be removed between rounds. A phone that went offline can rejoin by reloading the link.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.felt)
            .navigationTitle("Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
}

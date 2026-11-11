import ImposterHost
import SwiftUI

/// Hosting starts here: first the host's name, then the join code and the players who have arrived.
struct HostLobbyView: View {
    var chooseRules: () -> Void

    @Environment(HostStore.self) private var host

    var body: some View {
        Group {
            if let controller = host.controller {
                HostLobbyContent(controller: controller, chooseRules: chooseRules)
            } else {
                HostNameStep()
            }
        }
        .navigationTitle("Host a game")
        .navigationBarTitleDisplayMode(.inline)
    }
}

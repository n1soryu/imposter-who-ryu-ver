import SwiftUI

/// The house rules for a hosted game, sized to the players who have joined.
struct HostRulesView: View {
    var deal: () -> Void

    @Environment(HostStore.self) private var host

    var body: some View {
        RulesView(
            deal: deal,
            managePacks: nil,
            playerCount: host.controller?.session.players.count ?? 0,
            dealProblem: host.problem
        )
    }
}

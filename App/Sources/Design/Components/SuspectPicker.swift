import ImposterKit
import SwiftUI

/// A scrolling list of players to accuse. Tapping one selects it.
struct SuspectPicker: View {
    var players: [Player]
    @Binding var selection: Player.ID?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(players) { player in
                    SuspectRow(name: player.name, isSelected: selection == player.id) {
                        selection = player.id
                    }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

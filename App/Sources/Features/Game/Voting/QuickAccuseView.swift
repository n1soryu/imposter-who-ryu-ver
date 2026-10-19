import ImposterKit
import SwiftUI

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
                    Button(accuseLabel, action: accuseSuspect)
                        .buttonStyle(.pill)
                        .disabled(suspect == nil)
                    Button("We couldn't agree", action: accuseNobody)
                        .buttonStyle(.pillSecondary)
                }
            }
            .padding(Metrics.gutter)
            .background(Color.felt)
            .navigationTitle("Who did it?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
            }
        }
    }

    private var accuseLabel: String {
        guard let name = players.first(where: { $0.id == suspect })?.name else { return "Pick someone" }
        return "Accuse \(name)"
    }

    private func accuseSuspect() {
        guard let suspect else { return }
        dismiss()
        accuse(suspect)
    }

    private func accuseNobody() {
        dismiss()
        accuse(nil)
    }
}

import ImposterKit
import SwiftUI

/// Who's playing, in the order they're sitting.
struct PlayersView: View {
    var chooseRules: () -> Void

    @Environment(RosterStore.self) private var store
    @State private var newName = ""
    @State private var problem: String?
    @State private var renaming: Player?
    @State private var renameText = ""
    @FocusState private var isAddFieldFocused: Bool

    var body: some View {
        List {
            Section {
                ForEach(Array(store.players.enumerated()), id: \.element.id) { seat, player in
                    PlayerRow(seat: seat + 1, name: player.name) {
                        startRenaming(player)
                    }
                }
                .onMove(perform: store.move)
                .onDelete(perform: store.remove)
                .listRowBackground(Color.feltRaised)

                AddPlayerField(
                    name: $newName,
                    isFocused: $isAddFieldFocused,
                    isFull: store.players.count >= Roster.maximumPlayers,
                    submit: addPlayer
                )
                .listRowBackground(Color.feltRaised)
            } header: {
                Text("Add everyone in the order you're sitting. Clues go around the circle this way. Drag to reorder, swipe to remove.")
                    .font(.subheadline)
                    .foregroundStyle(Color.haze)
                    .textCase(nil)
                    .padding(.bottom, 8)
            } footer: {
                Text(problem ?? "")
                    .foregroundStyle(Color.imposterInk)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.felt)
        .navigationTitle("Who's playing?")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Shuffle seats", systemImage: "shuffle", action: shuffleSeats)
                    .disabled(store.players.count < 2)
            }
        }
        .safeAreaInset(edge: .bottom) {
            PlayersContinueBar(playerCount: store.players.count, action: chooseRules)
        }
        .alert("Rename player", item: $renaming) { player in
            TextField("Name", text: $renameText)
                .textInputAutocapitalization(.words)
            Button("Save") { rename(player) }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear(perform: focusFieldIfEmpty)
    }

    private func addPlayer() {
        do {
            try store.add(newName)
            newName = ""
            problem = nil
        } catch {
            problem = error.message
        }
        isAddFieldFocused = true
    }

    private func startRenaming(_ player: Player) {
        renameText = player.name
        renaming = player
    }

    private func rename(_ player: Player) {
        do {
            try store.rename(player.id, to: renameText)
            problem = nil
        } catch {
            problem = error.message
        }
    }

    private func shuffleSeats() {
        withAnimation { store.shuffleSeats() }
    }

    private func focusFieldIfEmpty() {
        if store.players.isEmpty { isAddFieldFocused = true }
    }
}

#Preview {
    let store = RosterStore(defaults: UserDefaults(suiteName: "preview-players") ?? .standard)
    for name in ["Ryu", "Aiko", "Ben"] {
        try? store.add(name)
    }
    return NavigationStack {
        PlayersView {}
    }
    .environment(store)
}

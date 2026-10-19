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
                        renameText = player.name
                        renaming = player
                    }
                }
                .onMove(perform: store.move)
                .onDelete(perform: store.remove)
                .listRowBackground(Color.feltRaised)

                AddPlayerField(name: $newName, isFocused: $isAddFieldFocused, isFull: store.players.count >= Roster.maximumPlayers) {
                    addPlayer()
                }
                .listRowBackground(Color.feltRaised)
            } header: {
                Text("Add everyone in the order you're sitting. Clues go around the circle this way. Drag to reorder, swipe to remove.")
                    .font(.subheadline)
                    .foregroundStyle(Color.haze)
                    .textCase(nil)
                    .padding(.bottom, 8)
            } footer: {
                if let problem {
                    Text(problem)
                        .foregroundStyle(Color.imposterInk)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.felt)
        .navigationTitle("Who's playing?")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Shuffle seats", systemImage: "shuffle") {
                    withAnimation { store.shuffleSeats() }
                }
                .disabled(store.players.count < 2)
            }
        }
        .safeAreaInset(edge: .bottom) {
            ContinueBar(playerCount: store.players.count, action: chooseRules)
        }
        .alert("Rename player", isPresented: isRenaming, presenting: renaming) { player in
            TextField("Name", text: $renameText)
                .textInputAutocapitalization(.words)
            Button("Save") { rename(player) }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            if store.players.isEmpty { isAddFieldFocused = true }
        }
    }

    private var isRenaming: Binding<Bool> {
        Binding { renaming != nil } set: { if $0 == false { renaming = nil } }
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

    private func rename(_ player: Player) {
        do {
            try store.rename(player.id, to: renameText)
            problem = nil
        } catch {
            problem = error.message
        }
    }
}

private struct PlayerRow: View {
    var seat: Int
    var name: String
    var rename: () -> Void

    var body: some View {
        Button(action: rename) {
            HStack(spacing: 16) {
                Text("\(seat)")
                    .font(.displaySemiBold(18, relativeTo: .body))
                    .foregroundStyle(Color.haze)
                    .monospacedDigit()
                    .frame(minWidth: 22, alignment: .trailing)
                Text(name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.cardStock)
                Spacer()
            }
            .contentShape(.rect)
        }
        .accessibilityLabel("Seat \(seat), \(name)")
        .accessibilityHint("Renames this player")
    }
}

private struct AddPlayerField: View {
    @Binding var name: String
    var isFocused: FocusState<Bool>.Binding
    var isFull: Bool
    var submit: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "plus")
                .foregroundStyle(Color.crewInk)
                .frame(minWidth: 22, alignment: .trailing)
                .accessibilityHidden(true)
            TextField(isFull ? "The table is full" : "Add a player", text: $name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused(isFocused)
                .onSubmit(submit)
                .disabled(isFull)
        }
    }
}

private struct ContinueBar: View {
    var playerCount: Int
    var action: () -> Void

    private var needed: Int { max(GameSettings.minimumPlayers - playerCount, 0) }

    var body: some View {
        VStack(spacing: 8) {
            Button("Choose house rules", action: action)
                .buttonStyle(.pill)
                .disabled(needed > 0)
            if needed > 0 {
                Text(needed == 1 ? "Add 1 more player to start." : "Add \(needed) more players to start.")
                    .font(.footnote)
                    .foregroundStyle(Color.haze)
            }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 12)
        .background(Color.felt)
    }
}

#Preview {
    let store = RosterStore(defaults: UserDefaults(suiteName: "preview-players")!)
    for name in ["Ryu", "Aiko", "Ben"] where store.players.contains(where: { $0.name == name }) == false {
        try? store.add(name)
    }
    return NavigationStack {
        PlayersView {}
    }
    .environment(store)
}

import ImposterKit
import SwiftUI

/// The group's own word packs.
struct PacksView: View {
    var openPack: (WordCategory.ID) -> Void

    @Environment(CustomPackStore.self) private var store
    @Environment(RulesStore.self) private var rules

    var body: some View {
        List {
            Section {
                ForEach(store.packs) { pack in
                    PackRow(pack: pack) { openPack(pack.id) }
                }
                .onDelete(perform: delete)
                .listRowBackground(Color.feltRaised)
            } footer: {
                Text("New packs are switched on in house rules straight away. Swipe to delete a pack.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.felt)
        .overlay {
            if store.packs.isEmpty {
                ContentUnavailableView {
                    Label("No packs yet", systemImage: "rectangle.stack.badge.plus")
                } description: {
                    Text("Make a pack of inside jokes, places you've been, or anything your group knows.")
                } actions: {
                    Button("New pack", action: createPack)
                        .buttonStyle(.pill)
                        .frame(maxWidth: 240)
                }
            }
        }
        .navigationTitle("Your word packs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New pack", systemImage: "plus", action: createPack)
            }
        }
    }

    private func createPack() {
        let id = store.create()
        rules.include(id)
        openPack(id)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            store.delete(store.packs[index].id)
        }
    }
}

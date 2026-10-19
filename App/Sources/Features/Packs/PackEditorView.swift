import ImposterKit
import SwiftUI

/// Edit one pack: its name and emoji, and its words.
struct PackEditorView: View {
    var packID: WordCategory.ID

    @Environment(CustomPackStore.self) private var store
    @State private var newWord = ""
    @State private var problem: String?
    @State private var editingWord: WordCard?
    @State private var isPasting = false
    @FocusState private var isAddFieldFocused: Bool

    var body: some View {
        if let pack = store.pack(withID: packID) {
            List {
                PackDetailsSection(packID: packID, name: pack.name, symbol: pack.symbol)

                Section {
                    ForEach(pack.cards, id: \.word) { card in
                        PackWordRow(card: card) { editingWord = card }
                    }
                    .onDelete(perform: deleteWords)
                    .listRowBackground(Color.feltRaised)

                    AddWordField(word: $newWord, isFocused: $isAddFieldFocused, submit: addWord)
                        .listRowBackground(Color.feltRaised)
                } header: {
                    HStack {
                        SectionTitle("Words")
                        Spacer()
                        Button("Paste a list", action: startPasting)
                            .font(.subheadline.weight(.semibold))
                            .textCase(nil)
                    }
                } footer: {
                    PackWordsFooter(problem: problem ?? store.saveProblem, wordCount: pack.cards.count)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.felt)
            .navigationTitle(pack.name)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editingWord) { card in
                WordEditorView(packID: packID, card: card)
            }
            .sheet(isPresented: $isPasting) {
                PasteListView(packID: packID)
            }
        } else {
            ContentUnavailableView("This pack was deleted", systemImage: "trash")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.felt)
        }
    }

    private func addWord() {
        do {
            try store.modify(packID) { pack throws(PackError) in
                try pack.addWord(newWord)
            }
            newWord = ""
            problem = nil
        } catch {
            problem = error.message
        }
        isAddFieldFocused = true
    }

    private func deleteWords(at offsets: IndexSet) {
        try? store.modify(packID) { pack in
            pack.removeWords(atOffsets: offsets)
        }
    }

    private func startPasting() {
        isPasting = true
    }
}

import ImposterKit
import SwiftUI

/// Add many words at once: one per line, or separated by commas.
struct PasteListView: View {
    var packID: WordCategory.ID

    @Environment(CustomPackStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Paris\nRome\nLisbon", text: $text, axis: .vertical)
                        .lineLimit(8...)
                        .focused($isFocused)
                } footer: {
                    Text("One word per line, or separated by commas. Duplicates are skipped.")
                }
                .listRowBackground(Color.feltRaised)
            }
            .scrollContentBackground(.hidden)
            .background(Color.felt)
            .navigationTitle("Paste a list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add words", action: addWords)
                        .disabled(WordCategory.splitList(text, separators: "\n,").isEmpty)
                }
            }
            .onAppear(perform: focus)
        }
    }

    private func addWords() {
        try? store.modify(packID) { pack in
            pack.addWords(fromList: text)
        }
        dismiss()
    }

    private func focus() {
        isFocused = true
    }
}

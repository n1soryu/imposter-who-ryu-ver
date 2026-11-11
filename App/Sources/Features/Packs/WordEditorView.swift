import ImposterKit
import SwiftUI

/// Edit one word, its hints for the imposter, and the similar words used in undercover mode.
struct WordEditorView: View {
    var packID: WordCategory.ID
    var card: WordCard

    @Environment(CustomPackStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    // Seeded once from the card being edited.
    @State private var word = ""
    @State private var hints = ""
    @State private var decoys = ""
    @State private var problem: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Word", text: $word, prompt: Text("Word").foregroundStyle(Color.haze))
                        .font(.displaySemiBold(22, relativeTo: .title3))
                        .textInputAutocapitalization(.words)
                } header: {
                    SectionTitle("Secret word")
                } footer: {
                    if let problem {
                        Text(problem).foregroundStyle(Color.imposterGlow)
                    }
                }

                Section {
                    TextField("Oven, slice, delivery", text: $hints, prompt: Text("Oven, slice, delivery").foregroundStyle(Color.haze), axis: .vertical)
                        .textInputAutocapitalization(.words)
                } header: {
                    SectionTitle("Hints")
                } footer: {
                    Text("Separate with commas. In hint mode the imposter gets one. Point near the word without giving it away.")
                }

                Section {
                    TextField("Calzone, flatbread", text: $decoys, prompt: Text("Calzone, flatbread").foregroundStyle(Color.haze), axis: .vertical)
                        .textInputAutocapitalization(.words)
                } header: {
                    SectionTitle("Similar words")
                } footer: {
                    Text("Separate with commas. In undercover mode the imposter gets one of these instead of the word.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.felt)
            .listRowBackground(Color.feltRaised)
            .navigationTitle("Edit word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
            .onAppear(perform: seed)
        }
    }

    private func seed() {
        word = card.word
        hints = card.hints.joined(separator: ", ")
        decoys = card.decoys.joined(separator: ", ")
    }

    private func save() {
        do {
            try store.modify(packID) { pack throws(PackError) in
                try pack.updateWord(
                    card.word,
                    to: word,
                    hints: WordCategory.splitList(hints),
                    decoys: WordCategory.splitList(decoys)
                )
            }
            dismiss()
        } catch {
            problem = error.message
        }
    }
}

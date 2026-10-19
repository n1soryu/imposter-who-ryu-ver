import ImposterKit
import SwiftUI

/// The pack's emoji and name. Edits are saved as you type.
struct PackDetailsSection: View {
    var packID: WordCategory.ID
    var name: String
    var symbol: String

    @Environment(CustomPackStore.self) private var store
    // Seeded once from the saved pack; after that this view is the only thing that edits these fields.
    @State private var nameText = ""
    @State private var symbolText = ""

    var body: some View {
        Section {
            HStack(spacing: 14) {
                TextField("🙂", text: $symbolText)
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .frame(width: 56)
                    .accessibilityLabel("Pack emoji")
                TextField("Pack name", text: $nameText)
                    .font(.displaySemiBold(24, relativeTo: .title2))
                    .foregroundStyle(Color.cardStock)
                    .textInputAutocapitalization(.words)
            }
            .listRowBackground(Color.feltRaised)
        } header: {
            SectionTitle("Pack")
        }
        .onAppear(perform: seed)
        .onChange(of: nameText, saveName)
        .onChange(of: symbolText, saveSymbol)
    }

    private func seed() {
        nameText = name
        symbolText = symbol
    }

    private func saveName() {
        let trimmed = nameText.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty == false else { return }
        try? store.modify(packID) { $0.name = trimmed }
    }

    /// Keeps only the last character typed, so the field always holds a single emoji.
    private func saveSymbol() {
        guard let last = symbolText.last else { return }
        if symbolText.count > 1 {
            symbolText = String(last)
        }
        try? store.modify(packID) { $0.symbol = String(last) }
    }
}

import ImposterKit
import SwiftUI

/// Which categories and difficulties the secret words come from.
struct WordsSection: View {
    @Binding var rules: HouseRules
    var library: WordLibrary
    var wordsInPlay: Int

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 8)]

    var body: some View {
        Section {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(library.categories) { category in
                    SelectableChip(
                        title: category.name,
                        symbol: category.symbol,
                        isSelected: rules.categoryIDs.contains(category.id)
                    ) {
                        rules.categoryIDs.formSymmetricDifference([category.id])
                    }
                }
            }
            .padding(.vertical, 4)

            HStack(spacing: 8) {
                ForEach(WordCard.Difficulty.allCases, id: \.self) { difficulty in
                    SelectableChip(title: difficulty.title, isSelected: rules.difficulties.contains(difficulty)) {
                        rules.difficulties.formSymmetricDifference([difficulty])
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            HStack {
                SectionTitle("Words")
                Spacer()
                Button(allSelected ? "Clear all" : "Select all", action: toggleAll)
                    .font(.subheadline.weight(.semibold))
                    .textCase(nil)
            }
        } footer: {
            Text("^[\(wordsInPlay) word](inflect: true) in play.")
        }
        .listRowBackground(Color.feltRaised)
    }

    private var allSelected: Bool {
        rules.categoryIDs.count == library.categories.count
    }

    private func toggleAll() {
        rules.categoryIDs = allSelected ? [] : Set(library.categories.map(\.id))
    }
}

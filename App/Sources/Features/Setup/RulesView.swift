import SwiftUI

/// Placeholder for house rules, which arrive with roadmap feature 1.3.
struct RulesView: View {
    var body: some View {
        ContentUnavailableView(
            "House rules are next",
            systemImage: "slider.horizontal.3",
            description: Text("Choosing categories, imposters and modes arrives in the next build.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.felt)
        .navigationTitle("House rules")
    }
}

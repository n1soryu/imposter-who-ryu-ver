import SwiftUI

/// Placeholder for the game setup flow, which arrives with roadmap features 1.2 and 1.3.
struct SetupView: View {
    var body: some View {
        ContentUnavailableView(
            "Players are next",
            systemImage: "person.3",
            description: Text("Adding players and choosing house rules arrive in the next build.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.felt)
        .navigationTitle("New game")
    }
}

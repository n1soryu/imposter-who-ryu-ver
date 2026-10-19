import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    private let steps: [(title: String, detail: String)] = [
        ("Pass the phone", "Each player holds to see their card in private. The crew all see the same secret word. The imposter doesn't."),
        ("Give one-word clues", "Go around the circle. Say something that proves you know the word without giving it away."),
        ("Talk it over", "Who hesitated? Whose clue was a bit too vague? Make your case."),
        ("Vote", "Everyone votes for who they think the imposter is. A tie means nobody is accused."),
        ("Last chance", "If the imposter is caught, they can still win by guessing the secret word."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(Array(steps.enumerated()), id: \.element.title) { index, step in
                        HStack(alignment: .firstTextBaseline, spacing: 16) {
                            Text("\(index + 1)")
                                .font(.display(28, relativeTo: .title2))
                                .foregroundStyle(Color.crewInk)
                                .frame(minWidth: 24, alignment: .leading)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.title)
                                    .font(.displaySemiBold(22, relativeTo: .title3))
                                    .foregroundStyle(Color.cardStock)
                                Text(step.detail)
                                    .foregroundStyle(Color.haze)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(Metrics.gutter)
            }
            .background(Color.felt)
            .navigationTitle("How to play")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    HowToPlayView()
}

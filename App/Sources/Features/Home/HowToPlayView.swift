import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(Array(RuleStep.all.enumerated()), id: \.element.title) { index, step in
                        RuleStepRow(number: index + 1, step: step)
                    }
                }
                .padding(Metrics.gutter)
            }
            .background(Color.felt)
            .navigationTitle("How to play")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
}

#Preview {
    HowToPlayView()
}

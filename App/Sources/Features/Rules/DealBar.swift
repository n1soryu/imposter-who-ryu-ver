import SwiftUI

/// The pinned Deal cards button under the house rules, with the reason it's unavailable, if any.
struct DealBar: View {
    var canDeal: Bool
    var problem: String?
    var deal: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button("Deal cards", action: deal)
                .buttonStyle(.pill)
                .disabled(canDeal == false)
            if let problem {
                Text(problem)
                    .font(.footnote)
                    .foregroundStyle(Color.imposterInk)
            }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 12)
        .background(Color.felt)
    }
}

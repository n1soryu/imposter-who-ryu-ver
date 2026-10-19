import SwiftUI

/// Every ballot is in. Waits until the phone is where everyone can see it.
struct AllVotesInView: View {
    var count: Int
    var reveal: () -> Void

    var body: some View {
        AdaptiveScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                Text("All \(count) votes are in")
                    .font(.display(56))
                    .foregroundStyle(Color.cardStock)
                    .minimumScaleFactor(0.5)
                Text("Put the phone where everyone can see it.")
                    .font(.title3)
                    .foregroundStyle(Color.haze)
                    .padding(.top, 8)
                Spacer()
                Button("Reveal the vote", action: reveal)
                    .buttonStyle(.pill)
            }
        }
    }
}

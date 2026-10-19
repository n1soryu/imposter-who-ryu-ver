import SwiftUI

/// Talk it over before voting.
struct DiscussionView: View {
    var seconds: Int?
    var startVoting: () -> Void
    var quickVote: () -> Void

    var body: some View {
        AdaptiveScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                Text("Who's the imposter?")
                    .font(.display(56))
                    .foregroundStyle(Color.cardStock)
                    .minimumScaleFactor(0.5)
                Text("Talk it over. Who hesitated? Whose clue didn't quite fit?")
                    .font(.title3)
                    .foregroundStyle(Color.haze)
                    .padding(.top, 8)

                if let seconds {
                    Countdown(seconds: seconds)
                        .padding(.top, 24)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button("Vote in secret", action: startVoting)
                        .buttonStyle(.pill)
                    Button("We've agreed on someone", action: quickVote)
                        .buttonStyle(.pillSecondary)
                }
            }
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.felt)
    }
}

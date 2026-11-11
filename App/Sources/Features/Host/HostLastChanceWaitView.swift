import SwiftUI

/// Someone else was caught and is typing their last guess.
struct HostLastChanceWaitView: View {
    var accusedName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("Caught!")
                .font(.display(64))
                .foregroundStyle(Color.imposterInk)
            Text("\(accusedName) was the imposter. They're making one last guess at the word.")
                .font(.title3)
                .foregroundStyle(Color.cardStock)
                .padding(.top, 8)
            Spacer()
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.felt)
    }
}

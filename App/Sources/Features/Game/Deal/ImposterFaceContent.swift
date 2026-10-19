import SwiftUI

/// What an imposter reads on their dealt card, with the hint if the hint mode is on.
struct ImposterFaceContent: View {
    var hint: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("You're the imposter")
                .font(.display(40))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
            if let hint {
                VStack(spacing: 2) {
                    Text("Your hint")
                        .font(.subheadline)
                    Text(hint)
                        .font(.displaySemiBold(26, relativeTo: .title2))
                }
            } else {
                Text("Blend in. Listen to the clues and work out the word.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
        }
        .foregroundStyle(Color.felt)
    }
}

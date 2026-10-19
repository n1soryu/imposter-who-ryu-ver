import SwiftUI

/// "Pass the phone to Aiko": the private hand-off before someone sees their card or casts a vote.
struct PassThePhoneView: View {
    var name: String
    /// Progress shown at the top, such as "Card 2 of 5".
    var progress: String
    var confirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(progress)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.haze)

            Spacer()

            Text("Pass the phone to")
                .font(.title3)
                .foregroundStyle(Color.haze)
            Text(name)
                .font(.display(64))
                .foregroundStyle(Color.cardStock)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
            Text("Hold it so nobody else can see the screen.")
                .foregroundStyle(Color.haze)
                .padding(.top, 8)

            Spacer()

            Button("I'm \(name)", action: confirm)
                .buttonStyle(.pill)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PassThePhoneView(name: "Aiko", progress: "Card 2 of 5") {}
        .padding()
        .background(Color.felt)
}

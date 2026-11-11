import SwiftUI

/// The join QR code and link at full size, for friends arriving after the lobby filled up.
struct JoinLinkSheet: View {
    var url: URL

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    QRCodeView(text: url.absoluteString)
                        .frame(maxWidth: 320)
                    Text(url.absoluteString)
                        .font(.title3.weight(.semibold))
                        .textSelection(.enabled)
                        .foregroundStyle(Color.cardStock)
                    Text("Scan this with a phone camera, or type the link into a browser. Everyone must be on the same Wi-Fi or your Personal Hotspot.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.haze)
                }
                .padding(Metrics.gutter)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Color.felt)
            .navigationTitle("Join link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
}

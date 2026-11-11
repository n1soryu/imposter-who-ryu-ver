import ImposterHost
import SwiftUI

/// The join link and QR code, or in plain words why there isn't one yet.
struct HostJoinInfo: View {
    var controller: HostController
    var showsQRCode: Bool
    var showLink: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch controller.status {
            case .starting:
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Getting ready to host…")
                        .foregroundStyle(Color.haze)
                }
            case .failed(let message):
                Text(message)
                    .foregroundStyle(Color.imposterInk)
                Button("Try again", action: retry)
                    .buttonStyle(.pillSecondary)
            case .stopped:
                Text("Hosting is paused.")
                    .foregroundStyle(Color.haze)
                Button("Start hosting again", action: retry)
                    .buttonStyle(.pillSecondary)
            case .running:
                running
            }
        }
        .padding(.horizontal, Metrics.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var running: some View {
        if let url = controller.joinURL {
            if showsQRCode {
                Text("Friends scan this with their camera.")
                    .font(.title3)
                    .foregroundStyle(Color.cardStock)
                QRCodeView(text: url.absoluteString)
                    .frame(maxWidth: 200)
                    .frame(maxWidth: .infinity)
            }
            Text(url.absoluteString)
                .font(.title3.weight(.semibold))
                .textSelection(.enabled)
                .foregroundStyle(Color.crewInk)
            Text("Join the same Wi-Fi or your Personal Hotspot. If a friend can't connect, check that Imposter is switched on under Settings > Privacy & Security > Local Network.")
                .font(.footnote)
                .foregroundStyle(Color.haze)
            if showsQRCode == false {
                Button("Show join link again", action: showLink)
                    .buttonStyle(.pillSecondary)
            }
        } else {
            Text("This iPhone isn't on Wi-Fi yet. Join the same Wi-Fi as your friends, or turn on Personal Hotspot and have them join it.")
                .foregroundStyle(Color.imposterInk)
            Button("Check again", action: refresh)
                .buttonStyle(.pillSecondary)
        }
    }

    private func retry() {
        Task { await controller.restart() }
    }

    private func refresh() {
        controller.refreshAddress()
    }
}

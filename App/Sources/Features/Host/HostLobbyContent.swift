import ImposterHost
import SwiftUI

/// The lobby once hosting has started: how to join, who has joined, and the way on to house rules.
struct HostLobbyContent: View {
    var controller: HostController
    var chooseRules: () -> Void

    @State private var isShowingLink = false

    var body: some View {
        let players = controller.session.seats
        let hasCompany = players.count > 1

        List {
            Section {
                HostJoinInfo(controller: controller, showsQRCode: hasCompany == false, showLink: showLink)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 8)
            }

            Section {
                ForEach(players, id: \.player.id) { seat in
                    HostPlayerRow(
                        name: seat.player.name,
                        isHost: seat.isHost,
                        isConnected: seat.isConnected,
                        mark: nil,
                        remove: seat.isHost ? nil : { controller.kick(seat.player.id) }
                    )
                    .swipeActions {
                        if seat.isHost == false {
                            Button("Remove", role: .destructive) { controller.kick(seat.player.id) }
                        }
                    }
                }
                .listRowBackground(Color.feltRaised)
            } header: {
                Text("^[\(players.count) player](inflect: true)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.haze)
                    .textCase(nil)
            } footer: {
                if players.count < 3 {
                    Text("You need at least 3 players. Friends appear here as they join.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.felt)
        .safeAreaInset(edge: .bottom) {
            Button("Choose house rules", action: chooseRules)
                .buttonStyle(.pill)
                .disabled(players.count < 3)
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 12)
                .background(Color.felt)
        }
        .sheet(isPresented: $isShowingLink) {
            if let url = controller.joinURL {
                JoinLinkSheet(url: url)
            }
        }
        .onAppear { controller.refreshAddress() }
    }

    private func showLink() {
        controller.refreshAddress()
        isShowingLink = true
    }
}

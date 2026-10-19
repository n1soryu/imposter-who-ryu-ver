import ImposterKit
import SwiftUI

/// One player's turn with the phone: hand it over, peek at the card, hide it, pass it on.
///
/// Give this view an identity per player (`.id(player.id)`), so the peek state resets for each person.
struct DealView: View {
    var player: Player
    var role: Role
    var categoryName: String
    var categorySymbol: String
    var seatNumber: Int
    var seatCount: Int
    var done: () -> Void

    @State private var isHoldingPhone = false

    var body: some View {
        Group {
            if isHoldingPhone {
                PeekStep(
                    role: role,
                    categoryName: categoryName,
                    categorySymbol: categorySymbol,
                    isLastSeat: seatNumber == seatCount,
                    done: done
                )
            } else {
                PassThePhoneView(name: player.name, progress: "Card \(seatNumber) of \(seatCount)", confirm: takePhone)
            }
        }
        .transition(.opacity)
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.felt)
    }

    private func takePhone() {
        withAnimation(.snappy) { isHoldingPhone = true }
    }
}

#Preview {
    DealView(
        player: Player(name: "Aiko"),
        role: .imposter(hint: "Oven"),
        categoryName: "Food",
        categorySymbol: "🍕",
        seatNumber: 2,
        seatCount: 5
    ) {}
}

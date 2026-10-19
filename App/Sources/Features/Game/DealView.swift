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
                .transition(.opacity)
            } else {
                HandoffStep(name: player.name, seatNumber: seatNumber, seatCount: seatCount) {
                    withAnimation(.snappy) { isHoldingPhone = true }
                }
                .transition(.opacity)
            }
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.felt)
    }
}

// MARK: - Hand-off

private struct HandoffStep: View {
    var name: String
    var seatNumber: Int
    var seatCount: Int
    var confirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Card \(seatNumber) of \(seatCount)")
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

// MARK: - Peek

private struct PeekStep: View {
    var role: Role
    var categoryName: String
    var categorySymbol: String
    var isLastSeat: Bool
    var done: () -> Void

    @State private var isRevealed = false
    @State private var hasPeeked = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            Text("Category: \(categoryName)")
                .font(.headline)
                .foregroundStyle(Color.haze)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 24)

            HoldToRevealCard(
                isRevealed: $isRevealed,
                role: role,
                categorySymbol: categorySymbol
            )
            .frame(maxWidth: 300)
            .onChange(of: isRevealed) { _, revealed in
                if revealed { hasPeeked = true }
            }

            Spacer(minLength: 24)

            Text(hasPeeked ? "Remember it, then pass the phone on." : "Hold the card to peek. Let go to hide it.")
                .foregroundStyle(Color.haze)
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)

            Button(isLastSeat ? "Done, start the clues" : "Done, pass the phone", action: done)
                .buttonStyle(.pill)
                .disabled(hasPeeked == false)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { isRevealed = false }
        }
    }
}

/// Face down until held. Every face uses the same card stock and ink, so a glance across the table doesn't give the role away.
private struct HoldToRevealCard: View {
    @Binding var isRevealed: Bool
    var role: Role
    var categorySymbol: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            CardBack(symbol: categorySymbol)
                .rotation3DEffect(.degrees(reduceMotion || isRevealed == false ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .opacity(isRevealed ? 0 : 1)
            DealtCardFace(face: role.cardFace, symbol: categorySymbol)
                .rotation3DEffect(.degrees(reduceMotion || isRevealed ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                .opacity(isRevealed ? 1 : 0)
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.35, bounce: 0.2), value: isRevealed)
        .contentShape(.rect)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if isRevealed == false { isRevealed = true }
                }
                .onEnded { _ in
                    isRevealed = false
                }
        )
        .sensoryFeedback(.impact(weight: .light), trigger: isRevealed) { _, revealed in revealed }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isRevealed ? role.cardFace.spokenDescription : "Your card, face down")
        .accessibilityHint("Double-tap to show or hide your card.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { isRevealed.toggle() }
    }
}

private struct CardBack: View {
    var symbol: String

    var body: some View {
        PlayingCard(face: .feltRaised, misprint: .crewInk, cornerMark: symbol) {
            Text("?")
                .font(.display(140))
                .foregroundStyle(Color.crewInk)
        }
    }
}

private struct DealtCardFace: View {
    var face: CardFace
    var symbol: String

    var body: some View {
        PlayingCard(face: .cardStock, misprint: .haze, cornerMark: symbol) {
            switch face {
            case .word(let word):
                CardWord(text: word)
            case .imposter(let hint):
                VStack(spacing: 16) {
                    Text("You're the imposter")
                        .font(.display(40))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(Color.felt)
                    if let hint {
                        VStack(spacing: 2) {
                            Text("Your hint")
                                .font(.subheadline)
                            Text(hint)
                                .font(.displaySemiBold(26, relativeTo: .title2))
                        }
                        .foregroundStyle(Color.felt)
                    } else {
                        Text("Blend in. Listen to the clues and work out the word.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.felt)
                    }
                }
            }
        }
    }
}

extension CardFace {
    var spokenDescription: String {
        switch self {
        case .word(let word): "The secret word is \(word)."
        case .imposter(let hint?): "You're the imposter. Your hint is \(hint)."
        case .imposter(nil): "You're the imposter."
        }
    }
}

#Preview("Hand-off") {
    DealView(
        player: Player(name: "Aiko"),
        role: .crew(word: "Pizza"),
        categoryName: "Food",
        categorySymbol: "🍕",
        seatNumber: 2,
        seatCount: 5
    ) {}
}

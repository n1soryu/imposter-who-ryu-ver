import ImposterKit
import SwiftUI

/// Face down until held. Every face uses the same card stock and ink, so a glance across the table doesn't give the role away.
struct HoldToRevealCard: View {
    @Binding var isRevealed: Bool
    var face: CardFace
    var categorySymbol: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            CardBack(symbol: categorySymbol)
                .rotation3DEffect(.degrees(reduceMotion || isRevealed == false ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .opacity(isRevealed ? 0 : 1)
            DealtCardFace(face: face, symbol: categorySymbol)
                .rotation3DEffect(.degrees(reduceMotion || isRevealed ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                .opacity(isRevealed ? 1 : 0)
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.35, bounce: 0.2), value: isRevealed)
        .contentShape(.rect)
        .gesture(holdGesture)
        .sensoryFeedback(.impact(weight: .light), trigger: isRevealed) { _, revealed in revealed }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isRevealed ? face.spokenDescription : "Your card, face down")
        .accessibilityHint("Double-tap to show or hide your card.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, toggle)
    }

    /// Reveals while a finger is down and hides as soon as it lifts.
    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if isRevealed == false { isRevealed = true }
            }
            .onEnded { _ in
                isRevealed = false
            }
    }

    private func toggle() {
        isRevealed.toggle()
    }
}

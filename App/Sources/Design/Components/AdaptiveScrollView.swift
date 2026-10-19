import SwiftUI

/// Shows its content as laid out when it fits the screen, and makes it scrollable when it doesn't, such as at the largest Dynamic Type sizes.
struct AdaptiveScrollView<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
            ScrollView {
                content
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

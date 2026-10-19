import SwiftUI

/// A titled panel on the results screen.
struct FactGroup<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.displaySemiBold(20, relativeTo: .title3))
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.feltRaised, in: .rect(cornerRadius: 18))
        }
    }
}

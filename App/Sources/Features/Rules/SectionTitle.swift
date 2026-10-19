import SwiftUI

/// A form section header set in the display face.
struct SectionTitle: View {
    var title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.displaySemiBold(20, relativeTo: .title3))
            .foregroundStyle(Color.cardStock)
            .textCase(nil)
    }
}

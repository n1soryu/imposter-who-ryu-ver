import SwiftUI

/// A setting's name with a one-line explanation underneath.
struct RuleLabel: View {
    var title: String
    var detail: String

    init(_ title: String, detail: String) {
        self.title = title
        self.detail = detail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .foregroundStyle(Color.cardStock)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(Color.haze)
        }
    }
}

import UIKit

@MainActor
enum NavigationBarAppearance {
    /// Sets navigation titles in Bricolage on a felt bar. SwiftUI has no API for title fonts, so this goes through UIKit's appearance proxy once at launch.
    static func apply() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(resource: .felt)
        appearance.shadowColor = .clear

        let text = UIColor(resource: .cardStock)
        if let large = UIFont(name: Typeface.extraBold, size: 36) {
            appearance.largeTitleTextAttributes = [
                .font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: large),
                .foregroundColor: text,
            ]
        }
        if let inline = UIFont(name: Typeface.semiBold, size: 18) {
            appearance.titleTextAttributes = [
                .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: inline),
                .foregroundColor: text,
            ]
        }

        let bar = UINavigationBar.appearance()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
    }
}

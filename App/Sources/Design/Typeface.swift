import SwiftUI

// Palette colours (.felt, .feltRaised, .cardStock, .crewInk, .imposterInk, .haze) come from
// Assets.xcassets through Xcode's generated asset symbols. See docs/DESIGN.md.

/// PostScript names of the bundled Bricolage Grotesque cuts.
enum Typeface {
    static let extraBold = "BricolageGrotesque96ptExtraBold-ExtraBold"
    static let semiBold = "BricolageGrotesque96ptExtraBold-SemiBold"
}

extension Font {
    /// Display type for secret words and titles. Scales with Dynamic Type relative to `style`.
    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom(Typeface.extraBold, size: size, relativeTo: style)
    }

    /// Display type for buttons and short headings.
    static func displaySemiBold(_ size: CGFloat, relativeTo style: Font.TextStyle = .title3) -> Font {
        .custom(Typeface.semiBold, size: size, relativeTo: style)
    }
}

import ImposterKit
import SwiftUI

extension WordLibrary {
    static let empty = WordLibrary(categories: [])

    /// The bundled categories. The content tests guarantee they load, so a failure here is a build problem, not a runtime one.
    static func bundledOrEmpty() -> WordLibrary {
        do {
            return try bundled()
        } catch {
            assertionFailure("Bundled word library failed to load: \(error)")
            return .empty
        }
    }
}

extension EnvironmentValues {
    @Entry var wordLibrary: WordLibrary = .empty
}

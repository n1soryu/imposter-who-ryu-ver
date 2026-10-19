import Foundation

/// Every category available to play, in display order.
public struct WordLibrary: Hashable, Sendable {
    public enum LoadError: Error, Hashable, Sendable {
        case missingResources
        case invalidCategory(file: String, reason: String)
    }

    public let categories: [WordCategory]

    public init(categories: [WordCategory]) {
        self.categories = categories
    }

    /// The categories bundled with the app.
    public static func bundled() throws -> WordLibrary {
        guard let directory = Bundle.module.url(forResource: "Categories", withExtension: nil) else {
            throw LoadError.missingResources
        }
        return try load(from: directory)
    }

    /// Loads every `.json` category in a directory. Files are ordered by name, so a numeric prefix like `01-` sets the display order.
    public static func load(from directory: URL) throws -> WordLibrary {
        let files = try FileManager.default
            .contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        let decoder = JSONDecoder()
        let categories = try files.map { file in
            do {
                return try decoder.decode(WordCategory.self, from: Data(contentsOf: file))
            } catch {
                throw LoadError.invalidCategory(file: file.lastPathComponent, reason: String(describing: error))
            }
        }
        return WordLibrary(categories: categories)
    }

    public func category(withID id: WordCategory.ID) -> WordCategory? {
        categories.first { $0.id == id }
    }

    /// The categories with the given IDs, in library order.
    public func categories(withIDs ids: Set<WordCategory.ID>) -> [WordCategory] {
        categories.filter { ids.contains($0.id) }
    }

    public var cardCount: Int {
        categories.reduce(0) { $0 + $1.cards.count }
    }
}

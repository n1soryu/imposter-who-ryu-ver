import Foundation

/// Why a word couldn't be added to a custom pack.
public enum PackError: Error, Hashable, Sendable {
    case emptyWord
    case wordTooLong(limit: Int)
    case duplicateWord(existing: String)
}

/// Building and editing word packs made in the app. A custom pack is an ordinary `WordCategory` with a `custom-` ID, so it plays exactly like a bundled one.
extension WordCategory {
    public static let customIDPrefix = "custom-"
    public static let maximumWordLength = 40

    /// A new, empty pack.
    public static func custom(name: String, symbol: String) -> WordCategory {
        WordCategory(id: customIDPrefix + UUID().uuidString, name: name, symbol: symbol, cards: [])
    }

    public var isCustom: Bool {
        id.hasPrefix(Self.customIDPrefix)
    }

    /// Adds a word with optional hints and decoys. Blank entries and anything that gives the word away are dropped.
    @discardableResult
    public mutating func addWord(_ word: String, hints: [String] = [], decoys: [String] = []) throws(PackError) -> WordCard {
        let cleaned = try validatedWord(word, replacing: nil)
        let card = WordCard(word: cleaned, hints: Self.cleaned(hints, for: cleaned), decoys: Self.cleaned(decoys, for: cleaned))
        cards.append(card)
        return card
    }

    /// Replaces the card that currently has the word `original`.
    public mutating func updateWord(_ original: String, to word: String, hints: [String], decoys: [String]) throws(PackError) {
        guard let index = cards.firstIndex(where: { $0.word == original }) else { return }
        let cleaned = try validatedWord(word, replacing: original)
        cards[index].word = cleaned
        cards[index].hints = Self.cleaned(hints, for: cleaned)
        cards[index].decoys = Self.cleaned(decoys, for: cleaned)
    }

    public mutating func removeWords(atOffsets offsets: IndexSet) {
        for index in offsets.sorted(by: >) where cards.indices.contains(index) {
            cards.remove(at: index)
        }
    }

    /// Adds every word in a pasted list (one per line, or separated by commas), skipping blanks and duplicates.
    /// - Returns: How many words were added.
    @discardableResult
    public mutating func addWords(fromList text: String) -> Int {
        let before = cards.count
        for word in Self.splitList(text, separators: "\n,") {
            _ = try? addWord(word)
        }
        return cards.count - before
    }

    /// Splits "a, b,  ,c" into ["a", "b", "c"].
    public static func splitList(_ text: String, separators: String = ",") -> [String] {
        text.split(whereSeparator: { separators.contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }

    private func validatedWord(_ word: String, replacing original: String?) throws(PackError) -> String {
        let cleaned = word.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard cleaned.isEmpty == false else { throw .emptyWord }
        guard cleaned.count <= Self.maximumWordLength else { throw .wordTooLong(limit: Self.maximumWordLength) }

        let key = GuessMatcher.normalize(cleaned)
        if let existing = cards.first(where: { $0.word != original && GuessMatcher.normalize($0.word) == key }) {
            throw .duplicateWord(existing: existing.word)
        }
        return cleaned
    }

    /// Trims and de-duplicates entries, and drops any that contain the word, which would give it away.
    private static func cleaned(_ entries: [String], for word: String) -> [String] {
        let answer = GuessMatcher.normalize(word)
        var seen = Set<String>()
        return entries
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { entry in
                let key = GuessMatcher.normalize(entry)
                return key.isEmpty == false && key.contains(answer) == false && seen.insert(key).inserted
            }
    }
}

extension WordLibrary {
    /// The library with custom packs added after the bundled categories, sorted by name.
    public func merging(_ custom: [WordCategory]) -> WordLibrary {
        let bundled = categories.filter { $0.isCustom == false }
        let packs = custom.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return WordLibrary(categories: bundled + packs)
    }
}

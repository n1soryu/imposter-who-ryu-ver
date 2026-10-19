import Foundation
import ImposterKit
import Observation

/// Word packs made in the app, saved as JSON in Application Support.
@Observable
@MainActor
final class CustomPackStore {
    private(set) var packs: [WordCategory]
    /// Set when the packs couldn't be saved, so the editor can say so.
    private(set) var saveProblem: String?

    @ObservationIgnored private let fileURL: URL

    init(directory: URL = .applicationSupportDirectory) {
        fileURL = directory.appending(path: "customPacks.json")
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([WordCategory].self, from: data) {
            packs = saved
        } else {
            packs = []
        }
    }

    func pack(withID id: WordCategory.ID) -> WordCategory? {
        packs.first { $0.id == id }
    }

    /// Creates an empty pack and returns its ID.
    func create() -> WordCategory.ID {
        let pack = WordCategory.custom(name: "New pack", symbol: "✨")
        packs.append(pack)
        save()
        return pack.id
    }

    /// Changes one pack and saves. Errors from the change are passed on and nothing is saved.
    func modify(_ id: WordCategory.ID, _ change: (inout WordCategory) throws(PackError) -> Void) throws(PackError) {
        guard let index = packs.firstIndex(where: { $0.id == id }) else { return }
        var pack = packs[index]
        try change(&pack)
        if pack != packs[index] {
            packs[index] = pack
            save()
        }
    }

    func delete(_ id: WordCategory.ID) {
        packs.removeAll { $0.id == id }
        save()
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(packs).write(to: fileURL, options: .atomic)
            saveProblem = nil
        } catch {
            saveProblem = "Your packs couldn't be saved. Check your iPhone has free storage."
        }
    }
}

extension PackError {
    var message: String {
        switch self {
        case .emptyWord: "Type a word first."
        case .wordTooLong(let limit): "Words can be up to \(limit) characters."
        case .duplicateWord(let existing): "\(existing) is already in this pack."
        }
    }
}

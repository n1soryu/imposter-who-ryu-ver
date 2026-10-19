import ImposterKit

extension WordCard: @retroactive Identifiable {
    /// Words are unique within a pack, so the word identifies the card in pack editing screens.
    public var id: String { word }
}

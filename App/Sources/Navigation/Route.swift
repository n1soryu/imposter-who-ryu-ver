import ImposterKit

/// Screens reachable from the home screen, in the order a new game goes through them.
enum Route: Hashable {
    case players
    case rules
    case packs
    case pack(WordCategory.ID)
    case game
}

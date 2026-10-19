/// The troll-round choices on the house rules screen, and the chance each one stands for.
enum TrollFrequency: CaseIterable {
    case never, rare, sometimes, often

    var title: String {
        switch self {
        case .never: "Never"
        case .rare: "Rarely"
        case .sometimes: "Sometimes"
        case .often: "Often"
        }
    }

    var chance: Double {
        switch self {
        case .never: 0
        case .rare: 0.05
        case .sometimes: 0.15
        case .often: 0.3
        }
    }
}

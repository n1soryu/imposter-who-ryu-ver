/// One step of the rules, in the order a round is played.
struct RuleStep {
    var title: String
    var detail: String

    static let all = [
        RuleStep(title: "Pass the phone", detail: "Each player holds to see their card in private. The crew all see the same secret word. The imposter doesn't."),
        RuleStep(title: "Give one-word clues", detail: "Go around the circle. Say something that proves you know the word without giving it away."),
        RuleStep(title: "Talk it over", detail: "Who hesitated? Whose clue was a bit too vague? Make your case."),
        RuleStep(title: "Vote", detail: "Everyone votes for who they think the imposter is. A tie means nobody is accused."),
        RuleStep(title: "Last chance", detail: "If the imposter is caught, they can still win by guessing the secret word."),
    ]
}

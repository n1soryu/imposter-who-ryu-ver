import ImposterKit

/// Headline copy for each way a round can end.
struct ResultSummary {
    var headline: String
    var detail: String
    var isCrewWin: Bool

    init(round: Round, result: GameSession.RoundResult) {
        let name = { (id: Player.ID?) in id.flatMap { round.player($0)?.name } ?? "Someone" }
        isCrewWin = result.outcome.crewWon

        switch result.outcome {
        case .crewWins(let caught):
            headline = "The crew wins"
            detail = "\(name(caught)) was caught."
        case .imposterStoleWin(let caught, let guess):
            headline = "\(name(caught)) stole it"
            detail = "Caught, but they guessed \"\(guess)\". Imposters win."
        case .impostersWin(let accused?):
            headline = "Wrong person"
            detail = "\(name(accused)) was innocent. Imposters win."
        case .impostersWin(nil):
            headline = "Nobody was accused"
            detail = "The vote was split, so the imposters get away with it."
        case .trollRound:
            headline = "Troll round"
            detail = "Everyone was the imposter. Nobody had the word."
        }
    }
}

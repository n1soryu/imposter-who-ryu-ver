import Foundation
import Testing
@testable import ImposterKit

struct HostSessionTests {
    typealias F = HostFixtures

    // MARK: Lobby and joining

    @Test func hostIsSeatZeroAndAlwaysConnected() throws {
        var session = try F.lobby(players: 3)
        let hostID = session.host.player.id

        #expect(session.seats[0].isHost)
        #expect(session.seats[0].isConnected)
        #expect(session.seats.dropFirst().allSatisfy { $0.isHost == false })

        let before = session.version
        let r1 = session.setConnected(false, for: hostID)
        #expect(r1 == false)
        #expect(session.host.isConnected)
        #expect(session.version == before)
    }

    @Test func joiningSeatsPlayersInOrderWithUniqueHexTokens() throws {
        let session = try F.lobby(players: 5)

        #expect(session.players.map(\.name) == Array(Fixtures.names.prefix(5)))
        let tokens = session.seats.map(\.token)
        #expect(Set(tokens).count == 5)
        #expect(tokens.allSatisfy { $0.count == 32 && $0.allSatisfy(\.isHexDigit) })
        #expect(session.seats.allSatisfy { $0.isConnected })
    }

    @Test func tokensComeFromTheInjectedGenerator() throws {
        let first = try F.lobby(players: 3, seed: 5)
        let second = try F.lobby(players: 3, seed: 5)
        let other = try F.lobby(players: 3, seed: 6)

        #expect(first.seats.map(\.token) == second.seats.map(\.token))
        #expect(first.seats.map(\.token) != other.seats.map(\.token))
    }

    @Test func joinValidatesNamesLikeTheRoster() throws {
        var session = try F.lobby(players: 3)

        #expect(throws: HostError.nameEmpty) { try session.join(name: "   ") }
        #expect(throws: HostError.nameTooLong(limit: 20)) { try session.join(name: String(repeating: "x", count: 21)) }
        #expect(throws: HostError.nameTaken(existing: "Aiko")) { try session.join(name: " aIKO ") }
        #expect(throws: HostError.nameTaken(existing: "Ben")) { try session.join(name: "Bén") }

        let seat = try session.join(name: "  Sam   Lee ")
        #expect(seat.player.name == "Sam Lee")
    }

    @Test func joinFailsWhenTheTableIsFull() throws {
        var session = try F.lobby(players: 12)
        for index in 12..<Roster.maximumPlayers { try session.join(name: "Guest \(index)") }

        #expect(session.canJoin == false)
        #expect(throws: HostError.full(limit: 15)) { try session.join(name: "One More") }
    }

    @Test func failedJoinsDoNotChangeTheVersion() throws {
        var session = try F.lobby(players: 3)
        let version = session.version
        _ = try? session.join(name: "")
        #expect(session.version == version)
    }

    @Test func joinDuringARoundIsRefused() throws {
        var session = try F.started()
        #expect(session.canJoin == false)
        #expect(throws: HostError.roundInProgress) { try session.join(name: "Late") }
    }

    @Test func joinIsAllowedOnTheFinishedScreen() throws {
        var session = try F.inDiscussion()
        session.quickAccuse(nil)
        #expect(session.canJoin)
        let seat = try session.join(name: "Late")
        #expect(session.seat(for: seat.player.id) != nil)
    }

    @Test func errorCodesMatchTheSpec() {
        let codes = [
            HostError.nameEmpty, .nameTooLong(limit: 20), .nameTaken(existing: "A"), .full(limit: 15),
            .roundInProgress, .unknownToken, .seatTaken, .noPeeksLeft, .notAllowed,
        ].map(\.code)
        #expect(codes == ["nameEmpty", "nameTooLong", "nameTaken", "full", "roundInProgress", "unknownToken", "seatTaken", "noPeeksLeft", "notAllowed"])
    }

    // MARK: Resume, claim, connections

    @Test func resumeFindsTheSeatAndReconnectsIt() throws {
        var session = try F.lobby()
        let seat = session.seats[2]
        session.setConnected(false, for: seat.player.id)

        let resumed = try session.resume(token: seat.token)
        #expect(resumed.player == seat.player)
        #expect(session.seat(for: seat.player.id)?.isConnected == true)
        #expect(throws: HostError.unknownToken) { try session.resume(token: "nope") }
    }

    @Test func setConnectedOnlyBumpsTheVersionOnRealChanges() throws {
        var session = try F.lobby()
        let id = session.seats[1].player.id
        let version = session.version

        let r2 = session.setConnected(true, for: id)
        #expect(r2 == false)
        #expect(session.version == version)
        let r3 = session.setConnected(false, for: id)
        #expect(r3)
        #expect(session.version == version + 1)
    }

    @Test func claimOnlyTakesDisconnectedSeatsAndRevokesTheOldToken() throws {
        var session = try F.lobby()
        let seat = session.seats[1]

        #expect(throws: HostError.seatTaken) { try session.claim(playerID: seat.player.id) }
        #expect(throws: HostError.seatTaken) { try session.claim(playerID: session.host.player.id) }
        #expect(throws: HostError.notAllowed) { try session.claim(playerID: UUID()) }

        session.setConnected(false, for: seat.player.id)
        let claimed = try session.claim(playerID: seat.player.id)

        #expect(claimed.token != seat.token)
        #expect(claimed.isConnected)
        #expect(throws: HostError.unknownToken) { try session.resume(token: seat.token) }
        let r4 = try session.resume(token: claimed.token).player
        #expect(r4 == seat.player)
    }

    @Test func disconnectedSeatsStayInTheGame() throws {
        var session = try F.inClues()
        let id = session.seats[1].player.id
        session.setConnected(false, for: id)

        #expect(session.game != nil)
        #expect(session.seat(for: id) != nil)
        #expect(session.view(for: session.host.player.id).players.first { $0.id == id }?.isConnected == false)
    }

    // MARK: Kick and leave

    @Test func kickWorksInTheLobbyAndRevokesTheToken() throws {
        var session = try F.lobby()
        let seat = session.seats[2]

        let r5 = session.kick(seat.player.id)
        #expect(r5)
        #expect(session.seat(for: seat.player.id) == nil)
        #expect(throws: HostError.unknownToken) { try session.resume(token: seat.token) }
    }

    @Test func kickNeverRemovesTheHostOrAnUnknownSeat() throws {
        var session = try F.lobby()
        let r6 = session.kick(session.host.player.id)
        #expect(r6 == false)
        let r7 = session.kick(UUID())
        #expect(r7 == false)
    }

    @Test func kickIsRefusedMidRoundButAllowedWhenFinished() throws {
        var session = try F.inDiscussion()
        let id = session.seats[1].player.id

        let r8 = session.kick(id)
        #expect(r8 == false)
        session.quickAccuse(nil)
        let r9 = session.kick(id)
        #expect(r9)
    }

    @Test func leaveFreesTheSeatInTheLobbyOnly() throws {
        var lobby = try F.lobby()
        let id = lobby.seats[1].player.id
        let r10 = lobby.leave(id)
        #expect(r10)
        #expect(lobby.seat(for: id) == nil)
        let r11 = lobby.leave(lobby.host.player.id)
        #expect(r11 == false)

        var playing = try F.started()
        let r12 = playing.leave(playing.seats[1].player.id)
        #expect(r12 == false)
    }

    // MARK: Starting and dealing

    @Test func startNeedsThreePlayers() throws {
        var session = try F.lobby(players: 2)
        #expect(throws: GameError.deal(.notEnoughPlayers(minimum: 3))) {
            try session.start(rules: F.rules(), library: F.library)
        }
        #expect(session.game == nil)
        #expect(session.view(for: session.host.player.id).phase == .lobby(canStart: false))
    }

    @Test func startDealsToEverySeatOnce() throws {
        var session = try F.started()
        let version = session.version
        #expect(session.game?.round.players == session.players)

        try session.start(rules: F.rules(), library: F.library)
        #expect(session.version == version)
        #expect(session.game?.roundNumber == 1)
    }

    @Test func dealCompletesOnlyWhenEveryoneHasSeenTheirCard() throws {
        var session = try F.started()
        let ids = session.players.map(\.id)

        for id in ids.dropLast() {
            let r13 = session.cardSeen(by: id)
            #expect(r13)
            guard case .dealing? = session.game?.phase else {
                Issue.record("left the deal early")
                return
            }
        }
        let r14 = session.cardSeen(by: ids[0])
        #expect(r14 == false)
        let r15 = session.cardSeen(by: UUID())
        #expect(r15 == false)

        session.cardSeen(by: ids[3])
        #expect(session.game?.phase == .clues(lap: 1, turn: 0))
    }

    @Test func dealingViewListsWhoWeAreWaitingFor() throws {
        var session = try F.started()
        let ids = session.players.map(\.id)
        session.cardSeen(by: ids[1])

        guard case .dealing(_, _, let face, let seen, let waiting) = session.view(for: ids[1]).phase else {
            Issue.record("expected dealing")
            return
        }
        #expect(face == nil)
        #expect(seen)
        #expect(waiting == [ids[0], ids[2], ids[3]])
    }

    // MARK: Clues

    @Test func onlyTheCurrentClueGiverOrTheHostMayFinishATurn() throws {
        var session = try F.inClues()
        let current = try #require(session.game?.currentCluegiver).id
        let host = session.host.player.id
        let bystander = try #require(session.players.map(\.id).first { $0 != current && $0 != host })

        let r16 = session.clueDone(by: bystander)
        #expect(r16 == false)
        #expect(session.game?.phase == .clues(lap: 1, turn: 0))
        let r17 = session.clueDone(by: current)
        #expect(r17)
        #expect(session.game?.phase == .clues(lap: 1, turn: 1))

        let next = try #require(session.game?.currentCluegiver).id
        if next != host {
            let r18 = session.clueDone(by: host)
            #expect(r18)
            #expect(session.game?.phase == .clues(lap: 1, turn: 2))
        }
    }

    @Test func clueTimerRestartsOnEveryTurnAndDiscussion() throws {
        var session = try F.inClues()
        let host = session.host.player.id
        let at = { (seconds: TimeInterval) in F.t0.addingTimeInterval(seconds) }

        func secondsLeft(_ now: Date) -> Int? {
            if case .clues(_, _, _, _, let left) = session.view(for: host, now: now).phase { return left }
            return nil
        }

        #expect(secondsLeft(at(0)) == 30)
        #expect(secondsLeft(at(10)) == 20)
        #expect(secondsLeft(at(500)) == 0)

        session.clueDone(by: host, now: at(12))
        #expect(secondsLeft(at(12)) == 30)

        session.endClues(now: at(20))
        guard case .discussion(let left) = session.view(for: host, now: at(50)).phase else {
            Issue.record("expected discussion")
            return
        }
        #expect(left == 90)
    }

    @Test func timersAreNilWhenSwitchedOff() throws {
        var session = try F.inClues(settings: GameSettings(turnSeconds: nil, discussionSeconds: nil))
        let host = session.host.player.id

        guard case .clues(_, _, _, _, let turnLeft) = session.view(for: host).phase else {
            Issue.record("expected clues")
            return
        }
        #expect(turnLeft == nil)
        session.endClues()
        #expect(session.view(for: host).phase == .discussion(secondsLeft: nil))
    }

    @Test func endCluesAndStartVotingFollowGameSessionRules() throws {
        var session = try F.started()
        let r19 = session.endClues()
        #expect(r19 == false)
        let r20 = session.startVoting()
        #expect(r20 == false)

        session = try F.inClues()
        let r21 = session.endClues()
        #expect(r21)
        let r22 = session.endClues()
        #expect(r22 == false)
        let r23 = session.startVoting()
        #expect(r23)
        let r24 = session.startVoting()
        #expect(r24 == false)
    }

    // MARK: Voting

    @Test func secretVotesCanComeInAnyOrderAndFinishWhenEveryoneHasVoted() throws {
        var session = try F.inVoting()
        let ids = session.players.map(\.id)

        let r25 = session.vote(by: ids[2], for: ids[0])
        #expect(r25)
        let r26 = session.vote(by: ids[0], for: ids[1])
        #expect(r26)
        let r27 = session.vote(by: ids[3], for: ids[0])
        #expect(r27)
        guard case .voting? = session.game?.phase else {
            Issue.record("finished too early")
            return
        }
        let r28 = session.vote(by: ids[1], for: ids[0])
        #expect(r28)

        if case .voting? = session.game?.phase { Issue.record("should have finished") }
    }

    @Test func voteRejectsSelfVotesDoubleVotesAndOutsiders() throws {
        var session = try F.inVoting()
        let ids = session.players.map(\.id)

        let r29 = session.vote(by: ids[0], for: ids[0])
        #expect(r29 == false)
        let r30 = session.vote(by: UUID(), for: ids[0])
        #expect(r30 == false)
        let r31 = session.vote(by: ids[0], for: UUID())
        #expect(r31 == false)
        let r32 = session.vote(by: ids[0], for: ids[1])
        #expect(r32)
        let version = session.version
        let r33 = session.vote(by: ids[0], for: ids[2])
        #expect(r33 == false)
        #expect(session.version == version)
    }

    @Test func votingViewShowsWhoVotedButNotForWhom() throws {
        var session = try F.inVoting()
        let ids = session.players.map(\.id)
        session.vote(by: ids[1], for: ids[2])

        #expect(session.view(for: ids[1]).phase == .voting(voted: [ids[1]], youVoted: true))
        #expect(session.view(for: ids[2]).phase == .voting(voted: [ids[1]], youVoted: false))
    }

    @Test func revealVotesFinishesEarlyWithTheBallotsSoFar() throws {
        var session = try F.inVoting()
        let ids = session.players.map(\.id)
        let imposter = try F.imposter(in: session)
        for id in ids.prefix(2) where id != imposter { session.vote(by: id, for: imposter) }

        let r34 = session.revealVotes()
        #expect(r34)
        let r35 = session.revealVotes()
        #expect(r35 == false)
        if case .voting? = session.game?.phase { Issue.record("still voting") }
    }

    @Test func revealVotesWithNoBallotsAccusesNobody() throws {
        var session = try F.inVoting()
        session.revealVotes()
        guard case .finished(let result)? = session.game?.phase else {
            Issue.record("expected finished")
            return
        }
        #expect(result.outcome == .impostersWin(accused: nil))
    }

    @Test func quickAccuseWorksFromCluesDiscussionAndVoting() throws {
        for session in [try F.inClues(), try F.inDiscussion(), try F.inVoting()] {
            var session = session
            let crew = try F.crew(in: session)
            let r36 = session.quickAccuse(crew[0])
            #expect(r36)
            guard case .finished(let result)? = session.game?.phase else {
                Issue.record("expected finished")
                return
            }
            #expect(result.outcome == .impostersWin(accused: crew[0]))
            #expect(result.tally == nil)
        }

        var dealing = try F.started()
        let r37 = dealing.quickAccuse(nil)
        #expect(r37 == false)
    }

    // MARK: Last chance

    @Test func onlyTheAccusedImposterMayGuess() throws {
        var session = try F.inVoting()
        let imposter = try F.imposter(in: session)
        F.voteFor(imposter, in: &session)

        #expect(session.game?.phase == .lastChance(accused: imposter))
        let crew = try F.crew(in: session)[0]
        let r38 = session.guess(by: crew, text: "Quokkaburger")
        #expect(r38 == false)
        #expect(session.game?.phase == .lastChance(accused: imposter))

        let r39 = session.guess(by: imposter, text: "Quokkaburger")
        #expect(r39)
        guard case .finished(let result)? = session.game?.phase else {
            Issue.record("expected finished")
            return
        }
        #expect(result.outcome.impostersWon)
    }

    @Test func givingUpLetsTheCrewWin() throws {
        var session = try F.inVoting()
        let imposter = try F.imposter(in: session)
        F.voteFor(imposter, in: &session)

        let r40 = session.guess(by: imposter, text: nil)
        #expect(r40)
        guard case .finished(let result)? = session.game?.phase else {
            Issue.record("expected finished")
            return
        }
        #expect(result.outcome.crewWon)
    }

    @Test func guessIsIgnoredOutsideLastChance() throws {
        var session = try F.inVoting()
        let imposter = try F.imposter(in: session)
        let r41 = session.guess(by: imposter, text: "Quokkaburger")
        #expect(r41 == false)
    }

    // MARK: Peeks

    @Test func peeksAreLimitedToThreePerRound() throws {
        var session = try F.inClues()
        let crew = try F.crew(in: session)[0]
        let word = try #require(session.game?.round.card.word)

        for left in [2, 1, 0] {
            let r42 = try session.peek(by: crew)
            #expect(r42 == .word(word))
            #expect(session.view(for: crew).peeksLeft == left)
        }
        #expect(throws: HostError.noPeeksLeft) { try session.peek(by: crew) }

        let other = try F.crew(in: session)[1]
        #expect(session.view(for: other).peeksLeft == 3)
    }

    @Test func peeksResetEachRound() throws {
        var session = try F.inClues()
        let crew = try F.crew(in: session)[0]
        for _ in 0..<3 { _ = try session.peek(by: crew) }
        session.quickAccuse(nil)
        try session.nextRound(library: F.library)

        #expect(session.peeksUsed.isEmpty)
        #expect(session.view(for: crew).peeksLeft == 3)
    }

    @Test func peeksAreOnlyAllowedDuringTheRound() throws {
        var dealing = try F.started()
        let id = dealing.players[1].id
        #expect(throws: HostError.notAllowed) { try dealing.peek(by: id) }

        var lobby = try F.lobby()
        #expect(throws: HostError.notAllowed) { try lobby.peek(by: id) }

        var finished = try F.inDiscussion()
        finished.quickAccuse(nil)
        #expect(throws: HostError.notAllowed) { try finished.peek(by: id) }

        var voting = try F.inVoting()
        _ = try voting.peek(by: voting.players[1].id)
        var discussion = try F.inDiscussion()
        _ = try discussion.peek(by: discussion.players[1].id)
        #expect(throws: HostError.notAllowed) { try discussion.peek(by: UUID()) }
    }

    @Test func peekAllowedInLastChance() throws {
        var session = try F.inVoting()
        let imposter = try F.imposter(in: session)
        F.voteFor(imposter, in: &session)
        let r43 = try session.peek(by: imposter)
        #expect(r43 == .imposter(hint: nil))
    }

    @Test func undercoverPeekShowsTheDecoyAsAWord() throws {
        let session = try F.inClues(settings: GameSettings(imposterIntel: .decoy))
        var copy = session
        let imposter = try F.imposter(in: session)
        let decoy = try #require(session.game?.round.card.decoys.first)

        let r44 = try copy.peek(by: imposter)
        #expect(r44 == .word(decoy))
    }

    @Test func imposterPeekShowsTheHintWhenHintModeIsOn() throws {
        var session = try F.inClues(settings: GameSettings(imposterIntel: .hint))
        let imposter = try F.imposter(in: session)
        let hint = try #require(session.game?.round.card.hints.first)

        let r45 = try session.peek(by: imposter)
        #expect(r45 == .imposter(hint: hint))
    }

    // MARK: Next round and end game

    @Test func nextRoundSeatsLateJoinersAndKeepsScores() throws {
        var session = try F.inDiscussion()
        session.quickAccuse(nil)
        let scores = session.game?.scoreboard
        let late = try session.join(name: "Late")

        try session.nextRound(library: F.library)

        let game = try #require(session.game)
        #expect(game.roundNumber == 2)
        #expect(game.round.players.count == 5)
        #expect(game.round.player(late.player.id) != nil)
        #expect(game.scoreboard == scores)
        #expect(game.phase == .dealing(seat: 0))
        #expect(session.seen.isEmpty)
    }

    @Test func nextRoundDropsKickedPlayersAndFitsTheRules() throws {
        var session = try F.inDiscussion(players: 7, settings: GameSettings(imposterCount: 3))
        #expect(session.game?.rules.settings.imposterCount == 3)
        session.quickAccuse(nil)
        for id in session.players.map(\.id).suffix(4) { session.kick(id) }

        try session.nextRound(library: F.library)
        #expect(session.game?.round.players.count == 3)
        #expect(session.game?.rules.settings.imposterCount == 1)
    }

    @Test func nextRoundFailsWhenTooFewPlayersAreLeft() throws {
        var session = try F.inDiscussion(players: 3)
        session.quickAccuse(nil)
        session.kick(session.seats[2].player.id)

        #expect(throws: GameError.deal(.notEnoughPlayers(minimum: 3))) {
            try session.nextRound(library: F.library)
        }
        #expect(session.game?.roundNumber == 1)
    }

    @Test func nextRoundIsIgnoredUntilTheRoundFinishes() throws {
        var session = try F.inClues()
        let version = session.version
        try session.nextRound(library: F.library)
        #expect(session.version == version)
        #expect(session.game?.roundNumber == 1)
    }

    @Test func endGameGoesBackToTheLobbyKeepingEverySeat() throws {
        var session = try F.inClues()
        let seats = session.seats

        let r46 = session.endGame()
        #expect(r46)
        #expect(session.game == nil)
        #expect(session.seats == seats)
        #expect(session.seen.isEmpty && session.peeksUsed.isEmpty)
        #expect(session.canJoin)
        let r47 = session.endGame()
        #expect(r47 == false)
        #expect(session.view(for: seats[1].player.id).phase == .lobby(canStart: true))
    }

    // MARK: Versions and views

    @Test func versionOnlyIncreasesOnRealChanges() throws {
        var session = try F.inClues()
        let version = session.version

        session.clueDone(by: UUID())
        session.vote(by: session.players[0].id, for: session.players[1].id)
        session.revealVotes()
        session.cardSeen(by: session.players[0].id)
        #expect(session.version == version)

        session.endClues()
        #expect(session.version == version + 1)
    }

    @Test func viewsCarryTheVersionScoresAndRoundNumber() throws {
        var session = try F.inDiscussion()
        let imposter = try F.imposter(in: session)
        session.quickAccuse(imposter)

        let view = session.view(for: session.host.player.id)
        #expect(view.version == session.version)
        #expect(view.roundNumber == 1)
        #expect(view.players.map(\.id) == session.players.map(\.id))
        #expect(view.players[0].isHost)
        #expect(view.scores.count == 4)
        #expect(view.scores.map(\.points) == view.scores.map(\.points).sorted(by: >))
    }

    @Test func anUnjoinedPhoneSeesTheJoinScreenWithClaimableSeats() throws {
        var session = try F.lobby()
        let dropped = session.seats[2].player.id
        session.setConnected(false, for: dropped)

        let view = session.joinView()
        #expect(view.you == nil)
        #expect(view.phase == .join(canJoin: true, claimable: [dropped]))
        #expect(session.view(for: UUID()) == view)

        var playing = try F.started()
        #expect(playing.joinView().phase == .join(canJoin: false, claimable: []))
        playing.setConnected(false, for: playing.seats[1].player.id)
        #expect(playing.joinView().phase == .join(canJoin: false, claimable: [playing.seats[1].player.id]))
    }
}

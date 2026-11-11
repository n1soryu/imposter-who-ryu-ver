import Foundation
import Testing
@testable import ImposterKit

/// The JSON must match docs/HOST_MODE.md exactly, because the browser client is written against it.
struct HostProtocolTests {
    static let a = UUID(uuidString: "00000000-0000-0000-0000-00000000000A")!
    static let b = UUID(uuidString: "00000000-0000-0000-0000-00000000000B")!
    static let c = UUID(uuidString: "00000000-0000-0000-0000-00000000000C")!

    private func object(_ text: String) throws -> NSDictionary {
        try #require(JSONSerialization.jsonObject(with: Data(text.utf8)) as? NSDictionary)
    }

    private func encoded(_ message: ServerMessage) throws -> NSDictionary {
        try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(message)) as? NSDictionary)
    }

    private func decode(_ text: String) throws -> ClientMessage {
        try JSONDecoder().decode(ClientMessage.self, from: Data(text.utf8))
    }

    // MARK: Phone to host

    @Test func decodesEveryClientMessage() throws {
        #expect(try decode(#"{"type":"resume","token":"abc"}"#) == .resume(token: "abc"))
        #expect(try decode(#"{"type":"join","name":"Sam"}"#) == .join(name: "Sam"))
        #expect(try decode(#"{"type":"claim","playerId":"\#(Self.a.uuidString)"}"#) == .claim(playerID: Self.a))
        #expect(try decode(#"{"type":"cardSeen"}"#) == .cardSeen)
        #expect(try decode(#"{"type":"clueDone"}"#) == .clueDone)
        #expect(try decode(#"{"type":"vote","suspect":"\#(Self.b.uuidString)"}"#) == .vote(suspect: Self.b))
        #expect(try decode(#"{"type":"guess","text":"pizza"}"#) == .guess(text: "pizza"))
        #expect(try decode(#"{"type":"guess","text":null}"#) == .guess(text: nil))
        #expect(try decode(#"{"type":"peek"}"#) == .peek)
        #expect(try decode(#"{"type":"leave"}"#) == .leave)
    }

    @Test func decodesHostCommands() throws {
        for (name, command) in [
            ("start", HostCommand.start), ("endClues", .endClues), ("startVoting", .startVoting),
            ("revealVotes", .revealVotes), ("nextRound", .nextRound), ("endGame", .endGame),
        ] {
            #expect(try decode(#"{"type":"host","command":"\#(name)"}"#) == .host(command))
        }
        #expect(try decode(#"{"type":"host","command":"quickAccuse","playerId":"\#(Self.c.uuidString)"}"#) == .host(.quickAccuse(Self.c)))
        #expect(try decode(#"{"type":"host","command":"quickAccuse","playerId":null}"#) == .host(.quickAccuse(nil)))
        #expect(try decode(#"{"type":"host","command":"quickAccuse"}"#) == .host(.quickAccuse(nil)))
        #expect(try decode(#"{"type":"host","command":"kick","playerId":"\#(Self.a.uuidString)"}"#) == .host(.kick(Self.a)))
    }

    @Test func unknownTypesDecodeAsUnknownAndBrokenMessagesThrow() throws {
        #expect(try decode(#"{"type":"dance"}"#) == .unknown(type: "dance"))
        #expect(try decode(#"{"type":"host","command":"explode"}"#) == .unknown(type: "host"))
        #expect(throws: (any Error).self) { try decode(#"{"type":"join"}"#) }
        #expect(throws: (any Error).self) { try decode(#"{"type":"vote","suspect":"not-a-uuid"}"#) }
        #expect(throws: (any Error).self) { try decode(#"{"name":"Sam"}"#) }
    }

    // MARK: Host to phone

    @Test func encodesSimpleServerMessages() throws {
        #expect(try encoded(.welcome(playerID: Self.a, token: "tok")) == object(#"{"type":"welcome","playerId":"\#(Self.a.uuidString)","token":"tok"}"#))
        #expect(try encoded(.kicked) == object(#"{"type":"kicked"}"#))
        #expect(try encoded(.peek(face: .word("Pizza"), peeksLeft: 2)) == object(#"{"type":"peek","face":{"kind":"word","word":"Pizza"},"peeksLeft":2}"#))
        #expect(try encoded(.peek(face: .imposter(hint: nil), peeksLeft: 0)) == object(#"{"type":"peek","face":{"kind":"imposter","hint":null},"peeksLeft":0}"#))
        #expect(try encoded(.peek(face: .imposter(hint: "Slice"), peeksLeft: 1)) == object(#"{"type":"peek","face":{"kind":"imposter","hint":"Slice"},"peeksLeft":1}"#))
        #expect(
            try encoded(.error(.nameTaken(existing: "Sam")))
                == object(#"{"type":"error","code":"nameTaken","message":"Someone's already called Sam."}"#)
        )
    }

    private func view(_ phase: PlayerView.Phase, you: PlayerView.Identity? = .init(id: a, name: "Sam")) -> PlayerView {
        PlayerView(
            version: 12,
            you: you,
            players: [.init(id: Self.a, name: "Sam", isHost: true, isConnected: true)],
            scores: [.init(id: Self.a, points: 3)],
            roundNumber: 2,
            peeksLeft: 3,
            phase: phase
        )
    }

    private func stateJSON(_ phase: String, you: String = #"{"id":"\#(a.uuidString)","name":"Sam"}"#) -> String {
        """
        {"type":"state","view":{"version":12,"you":\(you),
        "players":[{"id":"\(Self.a.uuidString)","name":"Sam","isHost":true,"connected":true}],
        "scores":[{"id":"\(Self.a.uuidString)","points":3}],"roundNumber":2,"peeksLeft":3,"phase":\(phase)}}
        """
    }

    @Test func encodesAStateForEveryPhase() throws {
        let a = Self.a.uuidString, b = Self.b.uuidString
        let cases: [(PlayerView.Phase, String)] = [
            (.lobby(canStart: true), #"{"name":"lobby","canStart":true}"#),
            (
                .dealing(categoryName: "Food", categorySymbol: "fork.knife", face: .word("Pizza"), seen: false, waitingFor: [Self.a]),
                #"{"name":"dealing","categoryName":"Food","categorySymbol":"fork.knife","face":{"kind":"word","word":"Pizza"},"seen":false,"waitingFor":["\#(a)"]}"#
            ),
            (
                .dealing(categoryName: "Food", categorySymbol: "fork.knife", face: nil, seen: true, waitingFor: []),
                #"{"name":"dealing","categoryName":"Food","categorySymbol":"fork.knife","seen":true,"waitingFor":[]}"#
            ),
            (
                .clues(lap: 1, laps: 2, turnOrder: [Self.a, Self.b], current: Self.b, secondsLeft: 25),
                #"{"name":"clues","lap":1,"laps":2,"turnOrder":["\#(a)","\#(b)"],"current":"\#(b)","secondsLeft":25}"#
            ),
            (
                .clues(lap: 2, laps: 2, turnOrder: [Self.a], current: Self.a, secondsLeft: nil),
                #"{"name":"clues","lap":2,"laps":2,"turnOrder":["\#(a)"],"current":"\#(a)","secondsLeft":null}"#
            ),
            (.discussion(secondsLeft: nil), #"{"name":"discussion","secondsLeft":null}"#),
            (.discussion(secondsLeft: 90), #"{"name":"discussion","secondsLeft":90}"#),
            (.voting(voted: [Self.b], youVoted: false), #"{"name":"voting","voted":["\#(b)"],"youVoted":false}"#),
            (.lastChance(accused: Self.b, youAreAccused: true), #"{"name":"lastChance","accused":"\#(b)","youAreAccused":true}"#),
            (.join(canJoin: true, claimable: [Self.b]), #"{"name":"join","canJoin":true,"claimable":["\#(b)"]}"#),
            (
                .finished(.init(
                    outcome: .init(kind: .imposterStoleWin, playerID: Self.b, guess: "pizza"),
                    word: "Pizza", imposters: [Self.b], troll: false,
                    awards: [.init(id: Self.b, points: 2)], ballots: [.init(voter: Self.a, suspect: Self.b)]
                )),
                #"{"name":"finished","outcome":{"kind":"imposterStoleWin","playerId":"\#(b)","guess":"pizza"},"word":"Pizza","imposters":["\#(b)"],"troll":false,"awards":[{"id":"\#(b)","points":2}],"ballots":[{"voter":"\#(a)","suspect":"\#(b)"}]}"#
            ),
            (
                .finished(.init(
                    outcome: .init(kind: .impostersWin, playerID: nil, guess: nil),
                    word: "Pizza", imposters: [Self.b], troll: false, awards: [], ballots: nil
                )),
                #"{"name":"finished","outcome":{"kind":"impostersWin","playerId":null,"guess":null},"word":"Pizza","imposters":["\#(b)"],"troll":false,"awards":[],"ballots":null}"#
            ),
        ]
        for (phase, literal) in cases {
            #expect(try encoded(.state(view(phase))) == object(stateJSON(literal)), "\(literal)")
        }
    }

    @Test func anUnjoinedViewEncodesYouAsNull() throws {
        let literal = #"{"name":"join","canJoin":false,"claimable":[]}"#
        #expect(try encoded(.state(view(.join(canJoin: false, claimable: []), you: nil))) == object(stateJSON(literal, you: "null")))
    }

    @Test func playerViewsRoundTripThroughJSON() throws {
        var session = try HostFixtures.inVoting()
        session.vote(by: session.players[1].id, for: session.players[2].id)
        let imposter = try HostFixtures.imposter(in: session)
        var finished = session
        HostFixtures.voteFor(imposter, in: &finished)
        finished.guess(by: imposter, text: "Quokkaburger")

        for source in [try HostFixtures.lobby(), try HostFixtures.started(), try HostFixtures.inClues(), try HostFixtures.inDiscussion(), session, finished] {
            for seat in source.seats {
                let view = source.view(for: seat.player.id, now: HostFixtures.t0)
                let data = try JSONEncoder().encode(view)
                #expect(try JSONDecoder().decode(PlayerView.self, from: data) == view)
            }
        }
        let join = session.joinView()
        #expect(try JSONDecoder().decode(PlayerView.self, from: JSONEncoder().encode(join)) == join)
    }
}

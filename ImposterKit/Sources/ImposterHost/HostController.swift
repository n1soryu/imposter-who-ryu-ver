import Foundation
import ImposterKit
import Network
import Observation

/// A pair of ports: HTTP for the browser client, WebSocket for the game.
public struct PortPair: Hashable, Sendable {
    public var http: UInt16
    public var ws: UInt16

    public init(http: UInt16, ws: UInt16) {
        self.http = http
        self.ws = ws
    }

    /// The documented ports, then the fallbacks.
    public static let defaults = [
        PortPair(http: 8737, ws: 8738),
        PortPair(http: 8747, ws: 8748),
        PortPair(http: 8757, ws: 8758),
    ]
}

/// Runs a hosted game: owns the `HostSession`, serves the browser client and talks to every phone.
@MainActor
@Observable
public final class HostController {
    public enum Status: Equatable, Sendable {
        case stopped
        case starting
        case running
        /// A plain-English reason the listeners are down.
        case failed(String)
    }

    // MARK: Observable state

    public private(set) var session: HostSession
    public private(set) var status: Status = .stopped
    public private(set) var joinURL: URL?
    public private(set) var httpPort: UInt16?
    public private(set) var wsPort: UInt16?
    /// The word history. Save it when the game ends so words don't repeat.
    public private(set) var wordPicker: WordPicker
    /// The house rules the next `start()` uses.
    public var rules: HouseRules

    public let allowsRemoteHostCommands: Bool
    /// Dev server only: the host's own seat sees its card, gives its clues, votes and gives up a last-chance guess by itself.
    public var autoplaysHostSeat = false
    public let library: WordLibrary

    public var errorMessage: String? {
        if case .failed(let message) = status { message } else { nil }
    }

    public var hostPlayerID: Player.ID { session.host.player.id }

    /// What the host's own seat may see.
    public var hostView: PlayerView { session.view(for: hostPlayerID) }

    // MARK: Internals

    private struct Client {
        let peer: WebSocketPeer
        var playerID: Player.ID?
        var lastSent: Data?
        var reader: Task<Void, Never>?
    }

    @ObservationIgnored private let ports: [PortPair]
    @ObservationIgnored private let webRoot: URL?
    @ObservationIgnored private var http: HTTPServer?
    @ObservationIgnored private var websocket: WebSocketServer?
    @ObservationIgnored private var clients: [UUID: Client] = [:]
    @ObservationIgnored private var connectionByPlayer: [Player.ID: UUID] = [:]
    @ObservationIgnored private var starting = false

    public init(
        hostName: String,
        library: WordLibrary,
        allowsRemoteHostCommands: Bool = false,
        picker: WordPicker = WordPicker(),
        ports: [PortPair] = PortPair.defaults
    ) throws(HostError) {
        self.session = try HostSession(hostName: hostName)
        self.library = library
        self.rules = HouseRules.defaults(for: library)
        self.allowsRemoteHostCommands = allowsRemoteHostCommands
        self.wordPicker = picker
        self.ports = ports
        self.webRoot = Bundle.module.url(forResource: "Web", withExtension: nil)
    }

    // MARK: Listeners

    /// Binds the listeners (not named `start`, which is the game's), trying each port pair in turn. Does nothing if already running.
    public func startListening() async {
        guard status != .running, starting == false else { return }
        starting = true
        defer { starting = false }
        status = .starting
        await bind(candidates: ports, attempts: 1)
    }

    /// Rebinds the same ports, for when the app returns to the foreground. Phones reconnect by themselves.
    public func restart() async {
        guard starting == false else { return }
        guard let http = httpPort, let ws = wsPort else {
            await startListening()
            return
        }
        starting = true
        defer { starting = false }
        status = .starting
        teardown()
        await bind(candidates: [PortPair(http: http, ws: ws)], attempts: 8)
    }

    /// Closes the listeners and every connection.
    public func stopListening() {
        teardown()
        status = .stopped
    }

    private func teardown() {
        http?.stop()
        websocket?.stop()
        http = nil
        websocket = nil
        for client in clients.values {
            client.reader?.cancel()
            client.peer.close()
        }
        clients = [:]
        connectionByPlayer = [:]
        for seat in session.seats where seat.isHost == false {
            session.setConnected(false, for: seat.player.id)
        }
    }

    private func bind(candidates: [PortPair], attempts: Int) async {
        guard let webRoot else {
            status = .failed("The game's web page is missing from the app. Reinstall it and try again.")
            return
        }
        var lastError: (any Error)?
        for pair in candidates {
            for attempt in 0..<attempts {
                if attempt > 0 { try? await Task.sleep(for: .milliseconds(150)) }
                do {
                    let ws = try await WebSocketServer.start(
                        port: pair.ws,
                        onPeer: { [weak self] peer in
                            Task { @MainActor in self?.accept(peer) }
                        },
                        onFailure: { [weak self] error in
                            Task { @MainActor in self?.listenerFailed(error) }
                        }
                    )
                    do {
                        let http = try await HTTPServer.start(
                            port: pair.http,
                            wsPort: pair.ws,
                            root: webRoot,
                            onFailure: { [weak self] error in
                                Task { @MainActor in self?.listenerFailed(error) }
                            }
                        )
                        self.http = http
                    } catch {
                        ws.stop()
                        throw error
                    }
                    websocket = ws
                    httpPort = pair.http
                    wsPort = pair.ws
                    refreshAddress()
                    status = .running
                    broadcast()
                    return
                } catch {
                    lastError = error
                }
            }
        }
        status = .failed(Self.explain(lastError))
    }

    private func listenerFailed(_ error: NWError) {
        guard status == .running else { return }
        teardown()
        status = .failed(Self.explain(error))
    }

    /// Looks the Wi-Fi or hotspot address up again, for when the network changed.
    public func refreshAddress() {
        joinURL = httpPort.flatMap { LocalAddress.joinURL(port: $0) }
    }

    private static func explain(_ error: (any Error)?) -> String {
        let hint = "Check that you're on Wi-Fi or using a Personal Hotspot, and that Imposter is allowed under Settings > Privacy & Security > Local Network."
        if let error = error as? NWError, case .posix(let code) = error, code == .EADDRINUSE {
            return "Another app is already using the ports this game needs. Close other hosting apps and try again. \(hint)"
        }
        return "Couldn't start hosting. \(hint)"
    }

    // MARK: Connections

    private func accept(_ peer: WebSocketPeer) {
        guard websocket != nil else {
            peer.close()
            return
        }
        let id = peer.id
        let reader = Task { @MainActor [weak self] in
            for await event in peer.events {
                guard let self else { return }
                switch event {
                case .text(let text): self.received(text, from: id)
                case .closed: self.closed(id)
                }
            }
        }
        clients[id] = Client(peer: peer, playerID: nil, lastSent: nil, reader: reader)
        sendState(to: id)
    }

    private func closed(_ id: UUID) {
        guard let client = clients.removeValue(forKey: id) else { return }
        client.reader?.cancel()
        if let player = client.playerID, connectionByPlayer[player] == id {
            connectionByPlayer[player] = nil
            session.setConnected(false, for: player)
            broadcast()
        }
    }

    private func received(_ text: String, from id: UUID) {
        guard clients[id] != nil, let message = try? JSONDecoder().decode(ClientMessage.self, from: Data(text.utf8)) else { return }
        handle(message, from: id)
        changed()
    }

    private func handle(_ message: ClientMessage, from id: UUID) {
        let player = clients[id]?.playerID
        switch message {
        case .resume(let token):
            attempt(id) { () throws(HostError) -> Seat in try session.resume(token: token) }
        case .join(let name):
            attempt(id) { () throws(HostError) -> Seat in try session.join(name: name) }
        case .claim(let playerID):
            attempt(id) { () throws(HostError) -> Seat in try session.claim(playerID: playerID) }
        case .leave:
            guard let player, session.leave(player) else { return }
            detach(id)
        case .cardSeen:
            if let player { session.cardSeen(by: player) }
        case .clueDone:
            if let player { session.clueDone(by: player) }
        case .vote(let suspect):
            if let player { session.vote(by: player, for: suspect) }
        case .guess(let text):
            if let player { session.guess(by: player, text: text) }
        case .peek:
            guard let player else { return reply(.error(.notAllowed), to: id) }
            do {
                let face = try session.peek(by: player)
                reply(.peek(face: face, peeksLeft: session.peeksLeft(for: player)), to: id)
            } catch {
                reply(.error(error), to: id)
            }
        case .host(let command):
            guard allowsRemoteHostCommands, player != nil else { return reply(.error(.notAllowed), to: id) }
            perform(command)
        case .unknown:
            break
        }
        noteGameChanged()
    }

    /// Runs a seat-claiming change and binds the connection to the seat, or replies with why not.
    private func attempt(_ id: UUID, _ work: () throws(HostError) -> Seat) {
        do {
            let seat = try work()
            attach(id, to: seat)
        } catch {
            reply(.error(error), to: id)
        }
    }

    private func attach(_ id: UUID, to seat: Seat) {
        let player = seat.player.id
        // A connection that was someone else gives that seat up.
        if let previous = clients[id]?.playerID, previous != player { detach(id) }
        // One live connection per player: the newer one wins.
        if let older = connectionByPlayer[player], older != id, let client = clients.removeValue(forKey: older) {
            client.reader?.cancel()
            client.peer.close()
        }
        connectionByPlayer[player] = id
        clients[id]?.playerID = player
        reply(.welcome(playerID: player, token: seat.token), to: id)
    }

    private func detach(_ id: UUID) {
        guard let player = clients[id]?.playerID else { return }
        clients[id]?.playerID = nil
        if connectionByPlayer[player] == id {
            connectionByPlayer[player] = nil
            session.setConnected(false, for: player)
        }
    }

    private func perform(_ command: HostCommand) {
        switch command {
        case .start: try? start(rules: nil, picker: nil)
        case .endClues: endClues()
        case .startVoting: startVoting()
        case .quickAccuse(let accused): quickAccuse(accused)
        case .revealVotes: revealVotes()
        case .nextRound: try? nextRound()
        case .endGame: endGame()
        case .kick(let player): kick(player)
        }
    }

    // MARK: Sending

    private func reply(_ message: ServerMessage, to id: UUID) {
        guard let data = try? JSONEncoder().encode(message) else { return }
        clients[id]?.peer.send(String(decoding: data, as: UTF8.self))
    }

    private func sendState(to id: UUID) {
        guard let client = clients[id] else { return }
        let view = client.playerID.map { session.view(for: $0) } ?? session.joinView()
        guard let data = try? JSONEncoder().encode(ServerMessage.state(view)), data != client.lastSent else { return }
        clients[id]?.lastSent = data
        client.peer.send(String(decoding: data, as: UTF8.self))
    }

    /// Sends each connection its view, but only if it changed.
    private func broadcast() {
        for id in Array(clients.keys) { sendState(to: id) }
    }

    private func noteGameChanged() {
        if let picker = session.game?.picker { wordPicker = picker }
    }

    private func changed() {
        if autoplaysHostSeat { autoplayHostSeat() }
        noteGameChanged()
        broadcast()
    }

    /// Plays the host's seat with the simplest move each phase, so the Mac dev server can finish a round from browser tabs alone.
    private func autoplayHostSeat() {
        let host = hostPlayerID
        for _ in 0..<8 {
            let acted: Bool
            switch session.view(for: host).phase {
            case .dealing(_, _, _, let seen, _) where seen == false:
                acted = session.cardSeen(by: host)
            case .clues(_, _, _, let current, _) where current == host:
                acted = session.clueDone(by: host)
            case .voting(_, let youVoted) where youVoted == false:
                guard let suspect = session.players.first(where: { $0.id != host })?.id else { return }
                acted = session.vote(by: host, for: suspect)
            case .lastChance(_, let youAreAccused) where youAreAccused:
                acted = session.guess(by: host, text: nil)
            default:
                acted = false
            }
            guard acted else { return }
        }
    }

    // MARK: Host seat and host commands

    /// Deals round 1. Pass `rules` to override `self.rules`, and `picker` to continue a saved word history.
    public func start(rules: HouseRules? = nil, picker: WordPicker? = nil) throws(GameError) {
        if let rules { self.rules = rules }
        if let picker { wordPicker = picker }
        defer { changed() }
        try session.start(rules: self.rules, library: library, picker: wordPicker)
    }

    public func cardSeen() {
        session.cardSeen(by: hostPlayerID)
        changed()
    }

    public func clueDone() {
        session.clueDone(by: hostPlayerID)
        changed()
    }

    public func endClues() {
        session.endClues()
        changed()
    }

    public func startVoting() {
        session.startVoting()
        changed()
    }

    public func quickAccuse(_ accused: Player.ID?) {
        session.quickAccuse(accused)
        changed()
    }

    public func vote(for suspect: Player.ID) {
        session.vote(by: hostPlayerID, for: suspect)
        changed()
    }

    public func revealVotes() {
        session.revealVotes()
        changed()
    }

    /// The host's last-chance guess. `nil` gives up.
    public func guess(_ text: String?) {
        session.guess(by: hostPlayerID, text: text)
        changed()
    }

    /// Uses one of the host's peeks.
    public func peek() throws(HostError) -> CardFace {
        defer { changed() }
        return try session.peek(by: hostPlayerID)
    }

    public func nextRound() throws(GameError) {
        defer { changed() }
        try session.nextRound(library: library)
    }

    public func endGame() {
        session.endGame()
        changed()
    }

    /// Removes a player (lobby and finished screen only) and tells their phone.
    public func kick(_ player: Player.ID) {
        guard session.kick(player) else { return }
        if let id = connectionByPlayer.removeValue(forKey: player) {
            clients[id]?.playerID = nil
            if let data = try? JSONEncoder().encode(ServerMessage.kicked) {
                clients[id]?.peer.send(String(decoding: data, as: UTF8.self), thenClose: true)
            }
            clients[id]?.reader?.cancel()
            clients[id] = nil
        }
        changed()
    }
}

# Host mode (Phase 2)

The iPhone hosts a game and plays in it on native screens. Friends join from any phone's
browser by scanning a QR code, over local Wi-Fi or the host's Personal Hotspot. No internet.

This file is the contract between the engine (`ImposterKit`), the server (`ImposterHost`), the
browser client and the iPhone app. Change it first if the contract has to change.

## Decisions

- **The host plays** on native iPhone screens. The host is a seat like any other.
- **Dropped phones rejoin the same game.** A player whose phone sleeps, loses Wi-Fi or reloads
  the page gets their seat, card and vote back. The game waits for them. Nobody is removed
  mid-round.
- **Both vote styles stay:** secret ballots on each phone, or a quick group vote the host
  records on the iPhone.
- **Peek at your card:** during a round each player may look at their card again up to
  **3 times** (crew: the word, undercover: the decoy, imposter: "Imposter" plus the hint if
  hint mode is on). The count resets every round. The host enforces it, so the face is only sent
  in reply to a peek and never sits in the regular state.

## Privacy rules (tested)

1. A phone only ever receives its own `PlayerView`. Never send `Round`, `GameSession`, roles,
   the secret word, the decoy, the hint, imposter IDs, troll status or ballots to anyone
   before the `finished` phase.
2. A card face is sent only (a) in the `dealing` phase to its own player until they mark it
   seen, and (b) in a `peek` reply. It is built with `Role.cardFace`, so an undercover card is
   indistinguishable from a crew card.
3. During secret voting a phone sees who has voted, never who they voted for.
4. Tests encode every player's view in every phase and check the JSON contains no secret it
   shouldn't (word, decoy, hint, other players' roles).

## Engine changes (`ImposterKit`)

- `GameSession.finishDeal()`: moves `dealing` straight to `clues(lap: 1, turn: 0)`. Host mode
  tracks who has seen their card itself and calls this when everyone has.
- `GameSession.castBallot(by:for:)`: records a secret ballot in any order. Ignored unless the
  phase is `voting`, both IDs are players in the round, they differ, and the voter hasn't voted.
- `GameSession.nextRound(players:library:using:)`: deals the next round to a changed group
  (kicks and late joiners), keeping the scoreboard and word history. Rules are re-fitted to the
  new player count. Throws `.deal(.notEnoughPlayers)` below 3.
- Existing behaviour and tests stay unchanged.

## Host session (`ImposterKit/Sources/ImposterKit/Host/`)

`HostSession` is a value type with no networking. It owns:

- **Seats:** `[Seat]` in seating order. `Seat` has the `Player`, a secret `token`, `isHost`,
  and `isConnected`. The host is seat 0, always connected. Names follow `Roster` rules
  (trimmed, 1-20 characters, unique ignoring case and accents, at most 15 players).
- **The game:** `GameSession?`, `nil` in the lobby.
- **Per-round host state:** `seen: Set<Player.ID>` during the deal, `peeksUsed: [Player.ID: Int]`.
- A `version` counter that increases on every change.

Joining and connections:

- `join(name:)` → seat + token. Allowed in the lobby and on the `finished` screen. During a
  round it fails with `roundInProgress`. Late joiners play from the next round.
- `resume(token:)` → the seat for a known token (reconnect after sleep or reload).
- `claim(playerID:)` → a seat whose phone is currently disconnected, for a player whose
  browser lost its stored token. Gives the seat a new token, so the old one stops working.
- `setConnected(_:for:)` is called by the server as sockets open and close.
- `kick(_:)` (host only): lobby and `finished` only. The kicked seat's token is revoked.

Game actions, all ignored when they don't fit the current phase or player:

| Who | Action | Effect |
|---|---|---|
| host | `start(rules:library:)` | Deals round 1 to all seats (needs 3+) |
| any player | `cardSeen(by:)` | Marks their card seen. When all players have, calls `finishDeal()` |
| current clue-giver or host | `clueDone(by:)` | `clueGiven()` |
| host | `endClues()`, `startVoting()` | Same as `GameSession` |
| host | `quickAccuse(_:)` | `accuse(_:)` (quick group vote; `nil` means no agreement) |
| any player | `vote(by:for:)` | `castBallot`. When every player has voted, calls `finishVoting()` |
| host | `revealVotes()` | `finishVoting()` early with the ballots in so far |
| accused imposter | `guess(by:text:)` | `submitGuess` (`nil` text gives up) |
| any player | `peek(by:)` → `CardFace?` | In `clues`, `discussion`, `voting` or `lastChance`, if they have peeks left, uses one and returns their face |
| host | `nextRound(library:)` | Deals the next round to the current seats, resets `seen` and peeks |
| host | `endGame()` | Back to the lobby with everyone still seated |

`view(for: Player.ID) -> PlayerView` builds what that player may see.

## Network layout (`ImposterHost` package target)

- HTTP on port **8737** serves the bundled browser client (`Web/`) and `/config.js`, which sets
  `window.IMPOSTER = { wsPort: 8738 }`. Only `GET` of known files; everything else is 404.
- WebSocket on port **8738** (`NWProtocolWebSocket`). One text frame = one JSON message.
- If 8737 is busy, try 8747/8748, then 8757/8758. Keep the same ports for the life of the host
  screen so phones can reconnect after a restart.
- The join URL is `http://<ip>:<httpPort>/`. Prefer the Personal Hotspot interface (`bridge*`,
  usually `172.20.10.1`) when it has an IPv4 address, otherwise Wi-Fi (`en0`).
- `HostController` (`@MainActor`, `@Observable`) owns the `HostSession` and both listeners. After
  every change it rebuilds each connected player's view and sends it if it changed. The iPhone
  app and the Mac dev server both use it.
- `imposter-host-dev` (macOS executable): runs a `HostController` on the Mac with a host seat
  named "Host" and **remote host commands enabled**, so the whole game can be driven from browser
  tabs with `?dev=1`. Remote host commands are rejected in the iPhone app.

## Messages

All JSON objects with a `type`. IDs are UUID strings. Unknown types are ignored.

Phone → host:

```json
{"type":"resume","token":"…"}
{"type":"join","name":"Sam"}
{"type":"claim","playerId":"…"}
{"type":"cardSeen"}
{"type":"clueDone"}
{"type":"vote","suspect":"…"}
{"type":"guess","text":"pizza"}          // text null = give up
{"type":"peek"}
{"type":"leave"}                          // lobby only; frees the seat
{"type":"host","command":"start"}         // dev server only: start, endClues, startVoting,
                                          // quickAccuse (+ "playerId" or null), revealVotes,
                                          // nextRound, endGame, kick (+ "playerId")
```

Host → phone:

```json
{"type":"welcome","playerId":"…","token":"…"}   // after join, resume or claim; store the token
{"type":"state","view":{…}}                      // a full PlayerView, sent on every change
{"type":"peek","face":{"kind":"word","word":"Pizza"},"peeksLeft":2}
{"type":"error","code":"nameTaken","message":"Someone's already called Sam."}
{"type":"kicked"}
```

A phone with no session (before `welcome`) gets a `state` with phase `join` listing the seats it
may `claim` (disconnected seats) and whether joining is open.

Error codes: `nameEmpty`, `nameTooLong`, `nameTaken`, `full`, `roundInProgress`,
`unknownToken`, `seatTaken`, `noPeeksLeft`, `notAllowed`.

### `PlayerView`

```json
{
  "version": 12,
  "you": {"id": "…", "name": "Sam"},
  "players": [{"id": "…", "name": "Ana", "isHost": true, "connected": true}],
  "scores": [{"id": "…", "points": 3}],          // standings order
  "roundNumber": 2,
  "peeksLeft": 3,
  "phase": {"name": "…", …}
}
```

`phase` by `name`:

| `name` | Extra fields |
|---|---|
| `join` | `canJoin`, `claimable: [id]` |
| `lobby` | `canStart` (3+ players) |
| `dealing` | `categoryName`, `categorySymbol` (SF Symbol name; the web shows the name only), `face` (only while you haven't seen it), `seen: bool`, `waitingFor: [id]` |
| `clues` | `lap`, `laps`, `turnOrder: [id]`, `current: id`, `secondsLeft` (or null) |
| `discussion` | `secondsLeft` (or null) |
| `voting` | `voted: [id]`, `youVoted: bool` |
| `lastChance` | `accused: id`, `youAreAccused: bool` |
| `finished` | `outcome: {kind: "crewWins"|"imposterStoleWin"|"impostersWin"|"trollRound", playerId, guess}`, `word`, `imposters: [id]`, `troll: bool`, `awards: [{id, points}]`, `ballots: [{voter, suspect}]` or null |

`face` is `{"kind":"word","word":"…"}` or `{"kind":"imposter","hint":"…"|null}`.

Timers: the host sends `secondsLeft` as of the moment it builds the view, and phones count down
locally. Timers never advance the game by themselves, matching pass-and-play.

## iPhone app

- Home gets **Host a game** under New game.
- Host lobby: the host types their name (prefilled from the saved roster's first player), a QR
  code (CoreImage) and the URL as text, the joined players with connection dots, kick, and
  "Choose house rules", which opens the existing `RulesView` sized to the lobby's player count.
- While hosting: `isIdleTimerDisabled = true`. When the app returns to the foreground, restart
  the listeners on the same ports. Phones reconnect by themselves.
- `NSLocalNetworkUsageDescription` in `Info.plist`. If listening fails or permission is denied,
  say so in plain words and how to fix it in Settings.
- The host's own screens reuse the pass-and-play components (`HoldToRevealCard`,
  `SuspectPicker`, `Countdown`, `QuickAccuseView`, `ResultsView`, the scoreboard) and add
  host controls: next clue, skip to discussion, start secret vote, quick group vote, reveal
  votes now, next round, end game. The host also gets 3 peeks.
- Word history is shared with pass-and-play (same `wordHistory.v1` key).

## Browser client

Plain HTML, CSS and ES modules in `ImposterKit/Sources/ImposterHost/Web/`, no build step, no
third-party code, Riso deck design (`docs/DESIGN.md`): felt background, yellow crew ink, pink
only at the reveal, Bricolage Grotesque (copied into `Web/fonts/`).

- Plain HTTP means no `crypto.randomUUID`, clipboard or screen wake lock. The token comes from
  the host and is kept in `localStorage`.
- Reconnect automatically with backoff (0.5 s to 5 s) and on `visibilitychange`/`online`, then
  `resume`. Show a quiet "Reconnecting…" bar meanwhile.
- Card reveal is hold-to-reveal, as in the app. A peek shows the face only while held, and
  releasing it ends that peek. The button says how many peeks are left.
- Large tap targets, works from 320 px wide, respects `prefers-reduced-motion`.

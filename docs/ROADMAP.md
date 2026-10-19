# Roadmap

An ad-free, personal version of the "Imposter Who?" party game. It is installed with a free
Apple ID (no paid developer program), so there's no App Store, no in-app purchases and no
cloud services.

Status key: ✅ done · 🚧 in progress · ⬜ not started

## Phase 0 — Foundations

| # | Feature | Status |
|---|---|---|
| 0.1 | Repository, roadmap, conventions | ✅ |
| 0.2 | `ImposterKit` Swift package: the game engine (roles, modes, rounds, voting, scoring) | ✅ |
| 0.3 | Word content: categories with hints and decoy words, plus no-repeat word picking | ✅ |

## Phase 1 — Pass-and-play iOS app

Needs Xcode (free, Mac App Store).

| # | Feature | Status |
|---|---|---|
| 1.1 | Xcode project (XcodeGen), app shell, design system | ✅ |
| 1.2 | Players: add, rename, reorder, remember the group | ✅ |
| 1.3 | Game setup: categories, imposter count, modes, timers, house rules | ✅ |
| 1.4 | Card deal: pass-the-phone privacy screen and hold-to-reveal card | ✅ |
| 1.5 | Clue rounds: turn order, per-turn timer, round counter | ✅ |
| 1.6 | Discussion and voting: secret pass-and-vote, or a quick group vote | ✅ |
| 1.7 | Reveal: the imposter's last-chance word guess and the results screen | ✅ |
| 1.8 | Scoring and the scoreboard across a session | ✅ |
| 1.9 | Custom word packs (saved as JSON in the bundled category format) | ✅ |
| 1.10 | Polish: haptics, sound, animations, accessibility, app icon | ✅ |
| 1.11 | Install guide: free-provisioning sideload and the weekly refresh | ✅ |

## Phase 2 — Host mode (same-room multiplayer, any phone)

The iPhone hosts the game, and friends join by scanning a QR code with any phone browser (iOS or
Android), over local Wi-Fi or the host's hotspot. No internet needed.

| # | Feature | Status |
|---|---|---|
| 2.1 | Message protocol and host-side game session in `ImposterKit` | ⬜ |
| 2.2 | Embedded HTTP and WebSocket server (Network framework) | ⬜ |
| 2.3 | Browser client (bundled HTML/CSS/JS) | ⬜ |
| 2.4 | Lobby: QR join, player list, kick, reconnect | ⬜ |
| 2.5 | Private cards, clue turns and voting on each player's own phone | ⬜ |

## Phase 3 — Nice to have

| # | Feature | Status |
|---|---|---|
| 3.1 | Native iPhone client that joins a host without using the browser | ⬜ |
| 3.2 | Share and import custom word packs | ⬜ |

## Game modes (engine)

- **Classic:** everyone gets the word, and the imposter gets nothing.
- **Imposter hint:** the imposter gets a related clue word.
- **Undercover:** the imposter gets a similar decoy word and doesn't know they're the imposter.
- **Multiple imposters:** 1 to n imposters.
- **Troll rounds:** a configurable chance that everyone is secretly an imposter.
- **Last-chance guess:** a caught imposter can steal the win by guessing the word.

## Conventions

- Commits follow [Conventional Commits](https://www.conventionalcommits.org/):
  `feat(kit): …`, `fix(app): …`, `docs: …`, `test: …`, `chore: …`.
  Scopes are `kit`, `content`, `app`, `host`, `web`.
- Game rules live in `ImposterKit` with no UI, and they are covered by Swift Testing.
- Run tests with `scripts/test.sh`. It also works with only the Command Line Tools installed.

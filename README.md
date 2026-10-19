# imposter-who-ryu-ver

Our own ad-free take on the imposter party game. Everyone gets the secret word except
the imposter, who has to bluff their way through the clues.

## Project layout

| Path | What's there |
|---|---|
| `ImposterKit/` | Swift package with the game engine and word content. No UI. |
| `App/` | The SwiftUI iPhone app. |
| `project.yml` | XcodeGen spec that generates `Imposter.xcodeproj`. |
| `docs/` | [Roadmap](docs/ROADMAP.md), [design](docs/DESIGN.md), [word content](docs/CONTENT.md). |

## Running it

- **On your iPhone:** follow [docs/INSTALL.md](docs/INSTALL.md). In short: add your Apple ID to
  Xcode, then run `scripts/setup-signing.sh` once and `scripts/install-on-iphone.sh` each week.
- **In the simulator:** open `Imposter.xcodeproj`, pick a simulator and press Run.

To build from the terminal, run `scripts/build.sh`. It regenerates the project from
`project.yml` first (`brew install xcodegen`).

## Tools

| Script | What it does |
|---|---|
| `scripts/test.sh` | Runs the ImposterKit tests. |
| `scripts/build.sh` | Regenerates the project and builds the app. |
| `scripts/screenshots.sh <udid>` | Screenshots every screen on a simulator using debug scenes. |
| `scripts/render-icon.swift` | Redraws the app icon. |
| `scripts/render-sounds.swift` | Re-synthesizes the sound effects. |

## Tests

```sh
scripts/test.sh
```

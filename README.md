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

1. Open `Imposter.xcodeproj` in Xcode.
2. Copy `Config/Signing.local.xcconfig.example` to `Config/Signing.local.xcconfig` and set
   your Personal Team ID. A free Apple ID works.
3. Pick your iPhone or a simulator and press Run.

To build from the terminal, run `scripts/build.sh`. It regenerates the project first. After changing `project.yml` or adding files, run `xcodegen generate`
(`brew install xcodegen`).

## Tests

```sh
scripts/test.sh
```

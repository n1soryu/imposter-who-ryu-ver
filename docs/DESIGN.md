# Design: "Riso deck"

The game is about a secret card, so the app looks like a deck of risograph-printed playing
cards laid on a felt table.

## Principles

- **Dark on purpose.** A bright screen lets neighbours read your card while the phone is
  passed around, so the table is always dark.
- **Ink colour is information.** Yellow is the crew and the secret word. Pink is the
  imposter. Never use either colour for decoration.
- **One loud element: the card.** It's big, slightly tilted, and has a second ink printed
  off-register behind it. Everything around it stays quiet: left-aligned text, plain
  lists, no gradients, no soft drop shadows.
- **Plain, sentence-case copy.** Buttons say exactly what happens ("Deal cards", not "Continue").

## Palette

Colours live in `App/Resources/Assets.xcassets` and are used through generated symbols
(`Color.felt` and so on).

| Name | Hex | Role |
|---|---|---|
| `felt` | `#1E1A3C` | Background: the table |
| `feltRaised` | `#2B2652` | Secondary buttons, rows |
| `cardStock` | `#F3F4FF` | Primary text on felt |
| `crewInk` | `#FFD23F` | Crew cards, primary actions |
| `imposterInk` | `#FF3D7F` | Imposter cards, danger |
| `haze` | `#8F8BB8` | Secondary text |

## Type

- **Bricolage Grotesque** ExtraBold and SemiBold (SIL Open Font License, `App/Resources/Fonts/OFL.txt`)
  for secret words, titles and buttons. Use `Font.display(_:)` and `Font.displaySemiBold(_:)`.
  Both scale with Dynamic Type.
- **SF Pro** (system) for body text and everything else.

## Components

- `PlayingCard`: the base card, with a face ink, a misprint ink and corner marks.
  `CrewCard` and `ImposterCard` are the two standard faces.
- `PillButtonStyle`: `.pill` for the main action on a screen and `.pillSecondary` for
  everything else.

# Changelog

All notable changes to this project are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/). The version matches `MARKETING_VERSION` in
`project.yml`.

## [Unreleased]

### Added

- MIT license.
- **Word length** house rule: play only one-word secret words ("Pizza"), only words of two
  or more ("Ice Cream", "Back to the Future"), or any. Hyphenated words like "Spider-Man"
  count as two. Saved rules from older versions load with "Any".
- 184 new words, bringing the library to 626 words. Every category now has at least 48.

### Changed

- Every hint was rewritten. In hint mode the imposter gets one hint at random, and some of
  them were in-jokes or trivia (Taco → "Tuesday", Seahorse → "Dad"), too vague, or fit
  another card just as well. Hints now name a well-known feature of the word, and each
  card has three of them.
- Mona Lisa, Santa Claus and Mr Bean left Famous People, which now holds only real people.
  Chess left Sports. DJ is only in Jobs, and Karaoke Bar left Places because Music has Karaoke.
- Stricter content tests: a hint can't be shared by two cards, be another card's word, or
  share a word with the answer or its aliases.
- The Apple Team ID is no longer stored in the Xcode project. It lives only in the
  untracked `Config/Signing.local.xcconfig`.

## [0.1.0] - 2026-10-20

The first playable version: a complete pass-and-play game on one iPhone (roadmap phases 0
and 1).

### Added

- **Game engine (`ImposterKit`).** Dealing roles, clue order, voting and scoring, in a Swift
  package with no UI and full Swift Testing coverage.
  - Imposter intel: nothing, a related hint word, or a decoy word (undercover mode).
  - Multiple imposters, always fewer than the crew.
  - Troll rounds, where everyone is secretly the imposter.
  - A last-chance guess for a caught imposter, which forgives case, accents, articles and plurals.
- **Word library.** 442 words in 12 categories, each with hints, decoys and a difficulty.
  Words don't repeat until every eligible word has come up, even across game nights.
  `scripts/test.sh` checks every category for duplicates, missing hints and leaky decoys.
- **Players screen.** Add, rename, reorder, shuffle and remove up to 15 players. The group is saved.
- **House rules screen.** Categories, difficulty, imposter count and intel, troll chance, clue
  rounds, turn and discussion timers, and whether an imposter may go first. Saved between games.
- **Card deal.** A pass-the-phone privacy screen and a hold-to-reveal card. Every card looks the
  same from across the table, so a glance never gives a role away.
- **Clue turns** with a per-turn timer and round counter, followed by a timed discussion.
- **Voting.** Secret pass-and-vote ballots, or a quick group vote. A tie means nobody is accused.
- **Round reveal** with the imposter's last-chance guess.
- **Game-night scoreboard** that totals points across rounds.
- **Custom word packs.** Write your own words or paste in a list. Packs are saved as JSON in the
  same format as the bundled categories.
- **"Riso deck" design.** A dark felt table, risograph-style cards, Bricolage Grotesque type
  and a matching app icon.
- **Sound and haptics.** Synthesized sound effects with an on/off toggle, plus haptics.
- **Accessibility.** Layouts hold up at the largest Dynamic Type sizes.
- **Install guide and scripts** for putting the app on an iPhone with a free Apple ID
  (`scripts/setup-signing.sh`, `scripts/install-on-iphone.sh`).
- Developer scripts for building, testing, screenshots and re-rendering the icon and sounds.

### Fixed

- Reveal screen layout, long words wrapping on cards, and the keyboard covering text fields.

[Unreleased]: https://github.com/n1soryu/imposter-who-ryu-ver/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/n1soryu/imposter-who-ryu-ver/releases/tag/v0.1.0

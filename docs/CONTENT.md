# Word content

Categories live in `ImposterKit/Sources/ImposterKit/Resources/Categories/`, one JSON file each.
The numeric file prefix (`01-`, `02-`, …) sets the order in the app.

```json
{
  "id": "food",
  "name": "Food",
  "symbol": "🍕",
  "cards": [
    { "word": "Pizza", "hints": ["Slice", "Oven", "Delivery"], "decoys": ["Calzone", "Flatbread"], "difficulty": "easy" }
  ]
}
```

| Field | Required | Purpose |
|---|---|---|
| `word` | yes | The secret word. |
| `hints` | at least 3 | One, picked at random, is shown to the imposter in hint mode. See [Writing hints](#writing-hints). |
| `decoys` | at least 2 | The imposter's word in undercover mode: a close cousin from the same category. |
| `aliases` | no | Other spellings that count when a caught imposter guesses the word. |
| `difficulty` | no (defaults to `medium`) | `easy`, `medium` or `hard`. Use `easy` for words kids know. |

## What makes a good word

- It can be hinted at in many ways: what it's like, where you find it, what it does.
- It has a close cousin (Pizza vs. Calzone), so a bluffing imposter has somewhere to hide.
- It isn't too obscure. Everyone in the crew needs to be able to come up with a clue.

## Writing hints

The imposter sees the category name and **one** hint, picked at random. So every hint on a card has to
work by itself. One weak hint ruins a round.

A good hint is something most people would say about the word straight away: what it looks like, what
it does, where you find it, what it's made of or what it's famous for. Read it next to the category
name ("Animals: Pouch") and ask whether it points to this word. It should point near the word without
naming it.

Don't use:
- **In-jokes, memes, quotes or trivia.** Taco → "Tuesday", Donut → "Police" and Seahorse → "Dad" only make sense if you already know the joke.
- **Vague words.** Translator → "Between" and Platypus → "Weird" could mean almost anything.
- **Hints that fit another card just as well.** "Shell" fits Taco and Egg. "Uncle" fits The Lion King and Spider-Man.
- **Another card in the same category.** Saxophone → "Jazz" points to the Jazz card instead.
- **Part of the word or an alias.** "Lion cub" for The Lion King gives the answer away.
- **Hints longer than four words.** A hint has to be readable in a quick peek.

Each category should only hold things of that kind. Famous People are real people, not paintings or
characters. A word shouldn't appear in two categories (DJ is in Jobs, not Music).

## Quality checks

`scripts/test.sh` checks every category and fails on:
- duplicate words
- fewer than 3 hints or 2 decoys on a card
- a hint that contains the word, is part of it, or shares a word with it or an alias
- the same hint on two cards in a category, or a hint that is another card's word
- a hint longer than four words, or a decoy that is also one of the card's hints
- a decoy that would count as a correct guess
- fewer than 45 words, or a difficulty level with no words

The tests can't judge meaning, so read new hints next to the category name before you add them.

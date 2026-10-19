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
| `hints` | at least 2 | One is shown to the imposter in hint mode. A hint should point *near* the word without naming it. |
| `decoys` | at least 1 | The imposter's word in undercover mode: a close cousin from the same category. |
| `aliases` | no | Other spellings that count when a caught imposter guesses the word. |
| `difficulty` | no (defaults to `medium`) | `easy`, `medium` or `hard`. Use `easy` for words kids know. |

## What makes a good word

- It can be hinted at in many ways: what it's like, where you find it, what it does.
- It has a close cousin (Pizza vs. Calzone), so a bluffing imposter has somewhere to hide.
- It isn't too obscure. Everyone in the crew needs to be able to come up with a clue.

## Quality checks

`scripts/test.sh` checks every category and fails on:
- duplicate words
- missing hints or decoys
- a hint that contains the word
- a decoy that would count as a correct guess
- fewer than 30 words, or a difficulty level with no words

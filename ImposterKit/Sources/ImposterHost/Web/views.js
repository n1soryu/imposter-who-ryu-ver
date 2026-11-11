// DOM builders. Each screen takes the model and an `act` object of actions from app.js.
import {
  screenFor, nameOf, namesOf, remainingSeconds, formatClock, plural, waitingText,
  resultSummary, standings, turnStrip, peekLabel, faceText, PEEK_PHASES,
} from "./logic.js";

export function h(tag, props, ...children) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(props || {})) {
    if (v === null || v === undefined || v === false) continue;
    if (k.startsWith("on") && typeof v === "function") el.addEventListener(k.slice(2).toLowerCase(), v);
    else if (k === "class") el.className = v;
    else if (v === true) el.setAttribute(k, "");
    else el.setAttribute(k, v);
  }
  append(el, children);
  return el;
}

function append(el, children) {
  for (const c of children.flat()) {
    if (c === null || c === undefined || c === false) continue;
    el.append(c.nodeType ? c : document.createTextNode(String(c)));
  }
}

const btn = (label, props = {}) => h("button", { type: "button", ...props, class: props.class || "pill" }, label);
const secondary = (label, props = {}) => btn(label, { ...props, class: "pill pill-secondary" });
const countdown = (model, secondsLeft, label) => {
  const left = remainingSeconds(model, secondsLeft);
  if (left === null) return null;
  return h("p", { class: "clock", role: "timer", "aria-label": label }, h("span", { "data-countdown": String(secondsLeft), "data-received": String(model.receivedAt) }, left === 0 ? "Time's up" : formatClock(left)));
};

/** Updates every countdown in place. Called on a timer. */
export function tickCountdowns(model, root) {
  for (const el of root.querySelectorAll("[data-countdown]")) {
    const left = remainingSeconds(model, Number(el.dataset.countdown));
    const text = left === 0 ? "Time's up" : formatClock(left);
    if (el.textContent !== text) el.textContent = text;
  }
}

// ---- Card ----------------------------------------------------------------

/**
 * A card that shows its face only while pressed (pointer or Space/Enter).
 * `getFace` is read at press time; the face is removed from the DOM on release.
 * `hold` is shared state ({ active }) so app.js can defer re-rendering while held.
 */
export function holdCard({ id, getFace, symbol, label, hold, onRevealed, onReleased }) {
  const content = h("div", { class: "card-content" });
  const back = h("div", { class: "card-back", "aria-hidden": "true" }, h("span", { class: "card-back-text" }, "Hold to reveal"));
  const card = h("div", {
    class: "card", id, role: "button", tabindex: "0", "aria-pressed": "false",
    "aria-label": label || "Hold to reveal your card",
  }, h("span", { class: "corner top", "aria-hidden": "true" }, symbol), h("span", { class: "corner bottom", "aria-hidden": "true" }, symbol), back, content);
  const wrap = h("div", { class: "card-wrap" }, card);
  let pointer = null;
  let keyHeld = false;

  const show = () => {
    const face = getFace();
    if (!face || hold.active) return;
    hold.active = true;
    content.replaceChildren(faceContent(face));
    card.classList.add("revealed");
    card.setAttribute("aria-pressed", "true");
    onRevealed && onRevealed();
  };
  const hide = () => {
    if (!hold.active || !card.classList.contains("revealed")) return;
    hold.active = false;
    content.replaceChildren();
    card.classList.remove("revealed");
    card.setAttribute("aria-pressed", "false");
    onReleased && onReleased();
  };

  card.addEventListener("pointerdown", (e) => {
    if (pointer !== null || (e.pointerType === "mouse" && e.button !== 0)) return;
    e.preventDefault();
    pointer = e.pointerId;
    try { card.setPointerCapture(e.pointerId); } catch (_) {}
    show();
  });
  const up = (e) => {
    if (e.pointerId !== pointer) return;
    pointer = null;
    hide();
  };
  card.addEventListener("pointerup", up);
  card.addEventListener("pointercancel", up);
  card.addEventListener("lostpointercapture", up);
  card.addEventListener("contextmenu", (e) => e.preventDefault());
  card.addEventListener("keydown", (e) => {
    if ((e.key === " " || e.key === "Spacebar" || e.key === "Enter") && !e.repeat) {
      e.preventDefault();
      keyHeld = true;
      show();
    }
  });
  card.addEventListener("keyup", (e) => {
    if (keyHeld && (e.key === " " || e.key === "Spacebar" || e.key === "Enter")) {
      keyHeld = false;
      hide();
    }
  });
  card.addEventListener("blur", () => { keyHeld = false; pointer = null; hide(); });
  wrap.release = () => { keyHeld = false; pointer = null; hide(); };
  return wrap;
}

// Every dealt face uses the same stock and ink, whatever the role.
function faceContent(face) {
  const t = faceText(face);
  if (face.kind === "word") {
    return h("div", { class: "face face-word" }, h("p", { class: "face-title word", "aria-live": "polite" }, t.title));
  }
  return h("div", { class: "face face-imposter" },
    h("p", { class: "face-title" }, t.title),
    t.hintLabel ? h("p", { class: "face-hint-label" }, t.hintLabel) : null,
    h("p", { class: t.hintLabel ? "face-hint" : "face-note" }, t.subtitle));
}

/** The revealed card at the end of a round: the word on crew ink. Pink is only for the imposters. */
function wordCard(word) {
  return h("div", { class: "card-wrap" },
    h("div", { class: "card card-final", role: "img", "aria-label": `The word was ${word}` },
      h("div", { class: "card-content" }, h("div", { class: "face face-word" }, h("p", { class: "face-title word" }, word)))));
}

// ---- Screens -------------------------------------------------------------

function connecting() {
  return h("section", { class: "screen center" }, h("h1", { class: "title" }, "Imposter"), h("p", { class: "muted" }, "Connecting to the host…"));
}

function kicked(model, act) {
  return h("section", { class: "screen" },
    h("h1", { class: "title" }, "The host removed you"),
    h("p", { class: "muted" }, "You can join again if the game is open."),
    btn("Join again", { id: "join-again", onclick: act.joinAgain }));
}

function join(model, act) {
  const phase = model.view.phase;
  const view = model.view;
  const claimable = phase.claimable.map((id) => ({ id, name: nameOf(view, id) }));
  const submit = (e) => { e.preventDefault(); act.join(); };
  const input = h("input", {
    id: "name", name: "name", type: "text", maxlength: "20", autocomplete: "off", autocapitalize: "words",
    spellcheck: "false", enterkeyhint: "go", value: model.nameDraft, "aria-describedby": model.joinError ? "join-error" : null,
    "aria-invalid": model.joinError ? "true" : null,
    oninput: (e) => { model.nameDraft = e.target.value; },
  });
  return h("section", { class: "screen" },
    h("h1", { class: "title" }, "Imposter"),
    h("p", { class: "muted" }, "Everyone gets a secret word. One of you doesn't."),
    phase.canJoin
      ? h("form", { class: "stack", onsubmit: submit },
          h("label", { for: "name", class: "label" }, "Your name"),
          input,
          model.joinError ? h("p", { id: "join-error", class: "error", role: "alert" }, model.joinError) : null,
          h("button", { type: "submit", class: "pill", id: "join" }, "Join game"))
      : h("p", { class: "note", role: "status" }, "A round is already running. New players can join between rounds."),
    claimable.length > 0
      ? h("div", { class: "stack" },
          h("h2", { class: "heading" }, "Already playing?"),
          claimable.map((p) => secondary(`I'm ${p.name} — rejoin`, { onclick: () => act.claim(p.id) })))
      : null);
}

function playerList(view, { withYou = true } = {}) {
  return h("ul", { class: "list" }, view.players.map((p) =>
    h("li", { class: "row" },
      h("span", { class: "dot " + (p.connected ? "on" : "off"), role: "img", "aria-label": p.connected ? "Connected" : "Disconnected" }),
      h("span", { class: "row-name" }, p.name),
      withYou && view.you && p.id === view.you.id ? h("span", { class: "tag" }, "You") : null,
      p.isHost ? h("span", { class: "tag" }, "Host") : null)));
}

function lobby(model, act) {
  const view = model.view;
  const n = view.players.length;
  return h("section", { class: "screen" },
    h("h1", { class: "title" }, "Lobby"),
    h("p", { class: "muted", role: "status" }, n < 3 ? `Waiting for the host to start. ${n} ${plural(n, "player", "players")} so far, 3 needed.` : "Waiting for the host to start"),
    playerList(view),
    secondary("Leave game", { id: "leave", onclick: act.leave }));
}

function dealing(model, act, ctx) {
  const view = model.view;
  const p = view.phase;
  const symbol = (p.categoryName || "?").trim().charAt(0).toUpperCase();
  if (p.seen || !p.face) {
    const names = namesOf(view, p.waitingFor);
    return h("section", { class: "screen" },
      h("p", { class: "eyebrow" }, `Round ${view.roundNumber} · ${p.categoryName}`),
      h("h1", { class: "title" }, "Card hidden"),
      h("p", { class: "muted", role: "status" }, waitingText(names)),
      names.length ? h("ul", { class: "list" }, names.map((n) => h("li", { class: "row" }, h("span", { class: "row-name" }, n)))) : null);
  }
  return h("section", { class: "screen" },
    h("p", { class: "eyebrow" }, `Round ${view.roundNumber} · ${p.categoryName}`),
    h("h1", { class: "title" }, "Your card"),
    holdCard({
      id: "card", symbol, hold: ctx.hold,
      getFace: () => (model.view.phase.name === "dealing" ? model.view.phase.face : null),
      onRevealed: () => { model.revealedOnce = true; },
      onReleased: ctx.afterRelease,
    }),
    h("p", { class: "muted center-text" }, "Hold the card to see it. Let go to hide it. Keep it from your neighbours."),
    btn("I've seen my card", { id: "seen", disabled: !model.revealedOnce, onclick: act.cardSeen }),
    model.revealedOnce ? null : h("p", { class: "hint center-text" }, "Hold the card at least once first."));
}

function header(view, text) {
  return h("p", { class: "eyebrow" }, text);
}

function clues(model, act) {
  const view = model.view;
  const p = view.phase;
  const mine = !!view.you && p.current === view.you.id;
  const strip = turnStrip(view, p);
  return h("section", { class: "screen" },
    header(view, `Round ${view.roundNumber} · Lap ${p.lap} of ${p.laps}`),
    h("ol", { class: "strip", "aria-label": "Turn order" }, strip.map((s) =>
      h("li", { class: `chip ${s.state}`, "aria-current": s.state === "current" ? "step" : null },
        s.name, s.isYou ? " (you)" : ""))),
    mine
      ? [h("h1", { class: "title" }, "Your turn"), h("p", { class: "muted" }, "Say one clue out loud, then tap the button.")]
      : [h("h1", { class: "title" }, `${nameOf(view, p.current)} is giving a clue`), h("p", { class: "muted" }, "Listen for words that fit.")],
    countdown(model, p.secondsLeft, "Time left for this clue"),
    mine ? btn("Done with my clue", { id: "clue-done", class: "pill big", onclick: act.clueDone }) : null);
}

function discussion(model) {
  const view = model.view;
  return h("section", { class: "screen" },
    header(view, `Round ${view.roundNumber}`),
    h("h1", { class: "title" }, "Discussion"),
    h("p", { class: "muted" }, "Talk it over. The host starts the vote."),
    countdown(model, view.phase.secondsLeft, "Discussion time left"));
}

function voting(model, act) {
  const view = model.view;
  const p = view.phase;
  const me = view.you && view.you.id;
  const status = h("div", { class: "stack" },
    h("h2", { class: "heading" }, "Who has voted"),
    h("ul", { class: "list" }, view.players.map((pl) =>
      h("li", { class: "row" },
        h("span", { class: "check", "aria-hidden": "true" }, p.voted.includes(pl.id) ? "✓" : ""),
        h("span", { class: "row-name" }, pl.name),
        h("span", { class: "tag" }, p.voted.includes(pl.id) ? "Voted" : "Thinking")))));
  if (p.youVoted) {
    const waiting = view.players.length - p.voted.length;
    return h("section", { class: "screen" },
      header(view, `Round ${view.roundNumber}`),
      h("h1", { class: "title" }, "Vote locked in"),
      h("p", { class: "muted", role: "status" }, waiting > 0 ? waitingText(new Array(waiting).fill(0)) : "All votes are in."),
      status);
  }
  const options = view.players.filter((pl) => pl.id !== me);
  const picked = model.selectedSuspect;
  return h("section", { class: "screen" },
    header(view, `Round ${view.roundNumber}`),
    h("h1", { class: "title" }, "Who is the imposter?"),
    h("p", { class: "muted" }, "Pick one suspect. Your vote is secret."),
    h("div", { class: "stack", role: "radiogroup", "aria-label": "Suspects" }, options.map((pl) =>
      h("button", {
        type: "button", class: "choice" + (picked === pl.id ? " picked" : ""), role: "radio",
        "aria-checked": picked === pl.id ? "true" : "false", id: "suspect-" + pl.id,
        onclick: () => act.pickSuspect(pl.id),
      }, pl.name))),
    btn(picked ? `Vote for ${nameOf(view, picked)}` : "Pick a suspect", { id: "vote", disabled: !picked, onclick: act.vote }),
    status);
}

function lastChance(model, act) {
  const view = model.view;
  const p = view.phase;
  if (p.youAreAccused) {
    const submit = (e) => { e.preventDefault(); act.guess(); };
    return h("section", { class: "screen" },
      header(view, `Round ${view.roundNumber}`),
      h("h1", { class: "title" }, "You're caught"),
      h("p", { class: "muted" }, "Guess the secret word and you steal the win."),
      h("form", { class: "stack", onsubmit: submit },
        h("label", { for: "guess", class: "label" }, "Your guess"),
        h("input", {
          id: "guess", name: "guess", type: "text", maxlength: "60", autocomplete: "off", autocapitalize: "off",
          spellcheck: "false", enterkeyhint: "go", value: model.guessDraft,
          oninput: (e) => { model.guessDraft = e.target.value; },
        }),
        h("button", { type: "submit", class: "pill", id: "guess-go" }, "Guess"),
        secondary("Give up", { id: "give-up", onclick: act.giveUp })));
  }
  return h("section", { class: "screen" },
    header(view, `Round ${view.roundNumber}`),
    h("h1", { class: "title" }, `${nameOf(view, p.accused)} was caught`),
    h("p", { class: "muted", role: "status" }, "They get one guess at the word. Wait for it."));
}

function finished(model) {
  const view = model.view;
  const f = view.phase;
  const sum = resultSummary(view, f.outcome);
  const mine = f.awards.find((a) => view.you && a.id === view.you.id);
  return h("section", { class: "screen" },
    header(view, `Round ${view.roundNumber}`),
    h("h1", { class: "title" }, sum.headline),
    h("p", { class: "muted" }, sum.detail),
    f.troll ? h("p", { class: "note" }, "Everyone got the imposter card this round.") : null,
    h("p", { class: "eyebrow center-text" }, "The word was"),
    wordCard(f.word),
    h("div", { class: "stack" },
      h("h2", { class: "heading" }, plural(f.imposters.length, "The imposter", "The imposters")),
      h("div", { class: "chips" }, f.imposters.map((id) => h("span", { class: "chip imposter" }, nameOf(view, id), view.you && id === view.you.id ? " (you)" : "")))),
    f.awards.length
      ? h("div", { class: "stack" },
          h("h2", { class: "heading" }, "Points this round"),
          h("ul", { class: "list" }, f.awards.map((a) =>
            h("li", { class: "row" }, h("span", { class: "row-name" }, nameOf(view, a.id)), h("span", { class: "points" }, `+${a.points}`)))))
      : null,
    f.ballots && f.ballots.length
      ? h("div", { class: "stack" },
          h("h2", { class: "heading" }, "Votes"),
          h("ul", { class: "list" }, f.ballots.map((b) =>
            h("li", { class: "row" }, h("span", { class: "row-name" }, `${nameOf(view, b.voter)} voted for ${nameOf(view, b.suspect)}`)))))
      : null,
    h("div", { class: "stack" }, h("h2", { class: "heading" }, "Standings"), standingsList(view)),
    mine ? h("p", { class: "visually-hidden" }, `You earned ${mine.points} points this round.`) : null,
    h("p", { class: "muted center-text", role: "status" }, "Waiting for the host to start the next round."));
}

function standingsList(view) {
  return h("ol", { class: "list standings" }, standings(view).map((s) =>
    h("li", { class: "row" + (s.isYou ? " you" : "") },
      h("span", { class: "rank" }, String(s.rank)),
      h("span", { class: "row-name" }, s.name, s.isYou ? " (you)" : ""),
      h("span", { class: "points" }, String(s.points)))));
}

const SCREENS = { connecting, kicked, join, lobby, dealing, clues, discussion, voting, lastChance, finished };

// ---- Chrome: top bar, peek, scores sheet, toast, dev ----------------------

function topBar(model, act) {
  const view = model.view;
  const show = view && view.you && !["join", "lobby"].includes(view.phase.name);
  return h("header", { class: "topbar" },
    h("span", { class: "wordmark" }, "Imposter"),
    show ? secondary("Scores", { id: "scores-btn", class: "pill pill-secondary small", "aria-haspopup": "dialog", onclick: act.openScores }) : null);
}

function peekControl(model, act) {
  const view = model.view;
  if (!view || !view.you || !PEEK_PHASES.includes(view.phase.name)) return null;
  const left = view.peeksLeft;
  return h("div", { class: "peekbar" },
    secondary(peekLabel(left), {
      id: "peek", disabled: left <= 0 || model.peekPending || !!model.peek,
      "aria-label": left > 0 ? `See my card, ${left} ${plural(left, "peek", "peeks")} left` : "No peeks left",
      onclick: act.peek,
    }));
}

function peekSheet(model, act, ctx) {
  if (!model.peek) return null;
  const face = model.peek.face;
  const symbol = "?";
  return h("div", { class: "overlay", role: "dialog", "aria-modal": "true", "aria-label": "Your card" },
    h("div", { class: "sheet" },
      h("h2", { class: "title small" }, "Your card"),
      holdCard({
        id: "peek-card", symbol, hold: ctx.hold, label: "Hold to look at your card",
        getFace: () => (model.peek ? model.peek.face : null),
        onReleased: act.closePeek,
      }),
      h("p", { class: "muted center-text" }, "Hold the card to look. Letting go closes this peek."),
      secondary("Close without looking", { id: "peek-close", onclick: act.closePeek })));
}

function scoresSheet(model, act) {
  if (!model.scoresOpen || !model.view) return null;
  return h("div", { class: "overlay", role: "dialog", "aria-modal": "true", "aria-label": "Scores" },
    h("div", { class: "sheet" },
      h("h2", { class: "title small" }, "Scores"),
      standingsList(model.view),
      btn("Close", { id: "scores-close", onclick: act.closeScores })));
}

function devPanel(model, act) {
  const view = model.view;
  if (!view || !view.you) return null;
  const cmd = (label, command) => secondary(label, { class: "pill pill-secondary small", onclick: () => act.host(command) });
  return h("details", { class: "dev" },
    h("summary", {}, "Host controls (dev)"),
    h("div", { class: "dev-grid" },
      cmd("start", "start"), cmd("endClues", "endClues"), cmd("startVoting", "startVoting"),
      cmd("revealVotes", "revealVotes"), cmd("nextRound", "nextRound"), cmd("endGame", "endGame")),
    h("label", { for: "dev-target", class: "label" }, "Player"),
    h("select", { id: "dev-target", onchange: (e) => { model.devTarget = e.target.value; } },
      h("option", { value: "" }, "No one"),
      view.players.map((p) => h("option", { value: p.id, selected: model.devTarget === p.id }, p.name))),
    h("div", { class: "dev-grid" }, cmd("quickAccuse", "quickAccuse"), cmd("kick", "kick")));
}

/** Builds the whole page into a fragment. */
export function renderApp(model, act, ctx) {
  const screen = screenFor(model);
  const build = SCREENS[screen] || connecting;
  const frag = document.createDocumentFragment();
  if (model.conn === "closed" && !model.kicked) frag.append(h("div", { class: "reconnect", role: "status" }, "Reconnecting\u2026"));
  append(frag, [
    topBar(model, act),
    h("main", { class: "main" },
      build(model, act, ctx),
      screen === "connecting" || screen === "kicked" ? null : peekControl(model, act),
      ctx.dev ? devPanel(model, act) : null),
    peekSheet(model, act, ctx),
    scoresSheet(model, act),
    model.toast ? h("div", { class: "toast", role: "status", "data-id": String(model.toast.id) }, model.toast.text) : null,
  ]);
  return frag;
}

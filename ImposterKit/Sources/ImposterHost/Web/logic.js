// Pure state and copy helpers. No DOM here, so Node can import this file.

export const TOKEN_KEY = "imposter.token";
export const PEEK_PHASES = ["clues", "discussion", "voting", "lastChance"];

export function createModel() {
  return {
    conn: "connecting", // connecting | open | closed
    resuming: false,
    token: null,
    playerId: null,
    view: null,
    receivedAt: 0,
    peek: null, // { face }
    peekPending: false,
    kicked: false,
    toast: null, // { text, id }
    joinError: null,
    revealedOnce: false,
    selectedSuspect: null,
    nameDraft: "",
    guessDraft: "",
    scoresOpen: false,
    devTarget: "",
  };
}

let toastId = 0;
function toast(model, text) {
  model.toast = { text, id: ++toastId };
}

/** Applies one server message. Returns a list of effects for the caller: "saveToken" | "clearToken". */
export function applyMessage(model, msg, now = Date.now()) {
  const effects = [];
  if (!msg || typeof msg.type !== "string") return effects;
  switch (msg.type) {
    case "welcome":
      model.token = msg.token;
      model.playerId = msg.playerId;
      model.resuming = false;
      model.kicked = false;
      model.joinError = null;
      effects.push("saveToken");
      break;
    case "state": {
      const previous = model.view;
      model.view = msg.view;
      model.receivedAt = now;
      const phase = msg.view.phase.name;
      if (phase !== "dealing") model.revealedOnce = false;
      if (phase !== "voting") model.selectedSuspect = null;
      if (previous && previous.roundNumber !== msg.view.roundNumber) {
        model.revealedOnce = false;
        model.selectedSuspect = null;
      }
      // A peeked face never outlives the phases where peeking is allowed.
      if (!PEEK_PHASES.includes(phase)) {
        model.peek = null;
        model.peekPending = false;
      }
      if (phase !== "join") model.joinError = null;
      break;
    }
    case "peek":
      model.peek = { face: msg.face };
      model.peekPending = false;
      if (model.view) model.view = { ...model.view, peeksLeft: msg.peeksLeft };
      break;
    case "error":
      model.peekPending = false;
      switch (msg.code) {
        case "unknownToken":
          model.token = null;
          model.playerId = null;
          model.resuming = false;
          effects.push("clearToken");
          break;
        case "noPeeksLeft":
          toast(model, "No peeks left.");
          break;
        case "notAllowed":
          toast(model, "That isn't available right now.");
          break;
        default:
          if (model.view && model.view.phase.name === "join") model.joinError = msg.message || "Couldn't join.";
          else toast(model, msg.message || "Something went wrong.");
      }
      break;
    case "kicked":
      model.kicked = true;
      model.token = null;
      model.playerId = null;
      model.peek = null;
      model.scoresOpen = false;
      effects.push("clearToken");
      break;
  }
  return effects;
}

export function socketOpened(model) {
  model.conn = "open";
  model.resuming = !!model.token;
}

export function socketClosed(model) {
  model.conn = "closed";
  model.resuming = false;
  model.peekPending = false;
}

/** Which screen to show. */
export function screenFor(model) {
  if (model.kicked) return "kicked";
  if (!model.view) return "connecting";
  const name = model.view.phase.name;
  // The server sends a join view first on every new socket, before our resume is answered.
  if (name === "join" && (model.resuming || (model.token && model.conn !== "open"))) return "connecting";
  return name;
}

export function nameOf(view, id) {
  const p = view && view.players.find((x) => x.id === id);
  return p ? p.name : "Someone";
}

export function namesOf(view, ids) {
  return (ids || []).map((id) => nameOf(view, id));
}

export function remainingSeconds(model, secondsLeft, now = Date.now()) {
  if (secondsLeft === null || secondsLeft === undefined) return null;
  const elapsed = Math.floor((now - model.receivedAt) / 1000);
  return Math.max(0, secondsLeft - elapsed);
}

export function formatClock(seconds) {
  const m = Math.floor(seconds / 60);
  const s = String(seconds % 60).padStart(2, "0");
  return `${m}:${s}`;
}

export function plural(n, one, many) {
  return n === 1 ? one : many;
}

export function waitingText(names) {
  if (names.length === 0) return "Everyone is ready.";
  return `Waiting for ${names.length} ${plural(names.length, "player", "players")}`;
}

/** Headline and detail for each way a round ends. Mirrors the app's ResultSummary. */
export function resultSummary(view, outcome) {
  const who = (id) => (id ? nameOf(view, id) : "Someone");
  switch (outcome.kind) {
    case "crewWins":
      return { headline: "The crew wins", detail: `${who(outcome.playerId)} was caught.`, crew: true };
    case "imposterStoleWin":
      return {
        headline: `${who(outcome.playerId)} stole it`,
        detail: `Caught, but they guessed "${outcome.guess}". Imposters win.`,
        crew: false,
      };
    case "impostersWin":
      return outcome.playerId
        ? { headline: "Wrong person", detail: `${who(outcome.playerId)} was innocent. Imposters win.`, crew: false }
        : { headline: "Nobody was accused", detail: "The vote was split, so the imposters get away with it.", crew: false };
    case "trollRound":
      return { headline: "Troll round", detail: "Everyone was the imposter. Nobody had the word.", crew: false };
    default:
      return { headline: "Round over", detail: "", crew: false };
  }
}

/** Standings with shared ranks for ties, in the server's order. */
export function standings(view) {
  let rank = 0;
  let last = null;
  return view.scores.map((s, i) => {
    if (s.points !== last) rank = i + 1;
    last = s.points;
    return { id: s.id, name: nameOf(view, s.id), points: s.points, rank, isYou: !!view.you && s.id === view.you.id };
  });
}

/** Turn strip entries: who has gone this lap, who is up, who is next. */
export function turnStrip(view, phase) {
  const idx = phase.turnOrder.indexOf(phase.current);
  return phase.turnOrder.map((id, i) => ({
    id,
    name: nameOf(view, id),
    state: i < idx ? "done" : i === idx ? "current" : "next",
    isYou: !!view.you && id === view.you.id,
  }));
}

export function peekLabel(peeksLeft) {
  return peeksLeft > 0 ? `See my card (${peeksLeft} left)` : "No peeks left";
}

/** Text for a card face. Same shape for every role: nothing here says "imposter" in colour. */
export function faceText(face) {
  if (face.kind === "word") return { title: face.word, subtitle: null, label: face.word };
  const subtitle = face.hint ? face.hint : "Blend in. Listen to the clues and work out the word.";
  return {
    title: "You're the imposter",
    subtitle,
    hintLabel: face.hint ? "Your hint" : null,
    label: face.hint ? `You're the imposter. Your hint: ${face.hint}` : "You're the imposter",
  };
}

export function hostCommandMessage(command, playerId) {
  const msg = { type: "host", command };
  if (command === "quickAccuse") msg.playerId = playerId || null;
  else if (command === "kick") msg.playerId = playerId;
  return msg;
}

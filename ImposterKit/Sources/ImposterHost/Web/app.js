import {
  createModel, applyMessage, socketOpened, socketClosed, TOKEN_KEY, hostCommandMessage,
} from "./logic.js";
import { renderApp, tickCountdowns } from "./views.js";

const root = document.getElementById("app");
const model = createModel();
const dev = new URLSearchParams(location.search).get("dev") === "1";
const hold = { active: false };
let renderPending = false;
let ws = null;
let attempt = 0;
let retryTimer = null;
let hiddenAt = 0;
let toastTimer = null;
let lastToastId = 0;

// ---- Storage (may throw in private windows) --------------------------------
function readToken() {
  try { return localStorage.getItem(TOKEN_KEY); } catch (_) { return null; }
}
function writeToken(token) {
  try {
    if (token) localStorage.setItem(TOKEN_KEY, token);
    else localStorage.removeItem(TOKEN_KEY);
  } catch (_) {}
}
model.token = readToken();

// ---- Rendering --------------------------------------------------------------
function render() {
  // Never rebuild the page under a finger that is holding the card.
  if (hold.active) { renderPending = true; return; }
  renderPending = false;
  const active = document.activeElement;
  const focusId = active && active !== document.body ? active.id : null;
  const selStart = active && "selectionStart" in active ? active.selectionStart : null;
  const selEnd = active && "selectionEnd" in active ? active.selectionEnd : null;
  const scrollY = window.scrollY;
  root.replaceChildren(renderApp(model, actions, { hold, dev, afterRelease }));
  if (focusId) {
    const el = document.getElementById(focusId);
    if (el && !el.disabled) {
      el.focus({ preventScroll: true });
      if (selStart !== null) { try { el.setSelectionRange(selStart, selEnd); } catch (_) {} }
    }
  }
  if (Math.abs(window.scrollY - scrollY) > 1) window.scrollTo(0, scrollY);
  if (model.toast && model.toast.id !== lastToastId) {
    lastToastId = model.toast.id;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { model.toast = null; render(); }, 3500);
  }
}
function afterRelease() { render(); }

setInterval(() => tickCountdowns(model, root), 250);

// ---- Socket -----------------------------------------------------------------
function wsUrl() {
  const cfg = window.IMPOSTER && window.IMPOSTER.wsPort;
  const port = cfg || (Number(location.port || 80) + 1);
  return `ws://${location.hostname}:${port}`;
}

function send(obj) {
  if (ws && ws.readyState === 1) { ws.send(JSON.stringify(obj)); return true; }
  return false;
}

function connect() {
  clearTimeout(retryTimer);
  if (ws && ws.readyState <= 1) return;
  let sock;
  try { sock = new WebSocket(wsUrl()); } catch (_) { scheduleRetry(); return; }
  ws = sock;
  sock.onopen = () => {
    if (sock !== ws) return;
    attempt = 0;
    socketOpened(model);
    if (model.token) send({ type: "resume", token: model.token });
    render();
  };
  sock.onmessage = (event) => {
    if (sock !== ws) return;
    let msg;
    try { msg = JSON.parse(event.data); } catch (_) { return; }
    for (const effect of applyMessage(model, msg)) {
      if (effect === "saveToken") writeToken(model.token);
      if (effect === "clearToken") writeToken(null);
    }
    render();
  };
  sock.onclose = () => {
    if (sock !== ws) return;
    ws = null;
    socketClosed(model);
    render();
    scheduleRetry();
  };
  sock.onerror = () => {};
}

function scheduleRetry() {
  clearTimeout(retryTimer);
  const delay = Math.min(5000, 500 * 2 ** attempt);
  attempt += 1;
  retryTimer = setTimeout(connect, delay);
}

function reconnectNow() {
  attempt = 0;
  if (ws && ws.readyState === 1) return;
  if (ws && ws.readyState === 0) return;
  connect();
}

document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "hidden") {
    hiddenAt = Date.now();
    if (hold.active) releaseAll();
    return;
  }
  // A socket that sat in a sleeping tab is often dead without saying so.
  if (ws && ws.readyState === 1 && hiddenAt && Date.now() - hiddenAt > 5000) {
    const old = ws;
    ws = null;
    old.onclose = null;
    try { old.close(); } catch (_) {}
    socketClosed(model);
    render();
  }
  reconnectNow();
});
window.addEventListener("online", reconnectNow);
window.addEventListener("blur", () => { if (hold.active) releaseAll(); });

function releaseAll() {
  for (const wrap of document.querySelectorAll(".card-wrap")) if (wrap.release) wrap.release();
}

// ---- Actions ----------------------------------------------------------------
const actions = {
  join() {
    const name = model.nameDraft.trim();
    if (!name) { model.joinError = "Type your name first."; render(); return; }
    model.joinError = null;
    if (!send({ type: "join", name })) { model.joinError = "Not connected yet. Trying again…"; render(); }
  },
  claim(id) { send({ type: "claim", playerId: id }); },
  joinAgain() { model.kicked = false; render(); },
  leave() {
    if (send({ type: "leave" })) {
      model.token = null;
      model.playerId = null;
      writeToken(null);
      model.nameDraft = "";
    }
  },
  cardSeen() { send({ type: "cardSeen" }); },
  clueDone() { send({ type: "clueDone" }); },
  pickSuspect(id) { model.selectedSuspect = id; render(); },
  vote() { if (model.selectedSuspect) send({ type: "vote", suspect: model.selectedSuspect }); },
  guess() {
    const text = model.guessDraft.trim();
    if (!text) return;
    send({ type: "guess", text });
    model.guessDraft = "";
  },
  giveUp() { send({ type: "guess", text: null }); model.guessDraft = ""; },
  peek() {
    if (model.peekPending || model.peek) return;
    if (send({ type: "peek" })) { model.peekPending = true; render(); }
  },
  closePeek() { model.peek = null; render(); },
  openScores() { model.scoresOpen = true; render(); },
  closeScores() { model.scoresOpen = false; render(); },
  host(command) {
    if (!dev) return;
    if (command === "kick" && !model.devTarget) { model.toast = { text: "Pick a player to kick.", id: Date.now() }; render(); return; }
    send(hostCommandMessage(command, model.devTarget));
  },
};

document.addEventListener("keydown", (e) => {
  if (e.key === "Escape" && model.scoresOpen) { model.scoresOpen = false; render(); }
});

render();
connect();

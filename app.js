"use strict";

// ---- CONFIG (edit before launch) -------------------------------------------
const CONFIG = {
  freeLimit: 3,
  price: "$2.99",
  paymentLink: "",   // your Stripe/Gumroad/Lemon Squeezy payment link
  unlockHash: ""     // SHA-256 hex of the unlock code shown after payment
};
// -----------------------------------------------------------------------------

const KEY = "dayssince.v1";
const UNLOCK_KEY = "dayssince.unlocked";
const COLORS = ["#4F8EF7", "#34C759", "#FF9500", "#FF3B30", "#AF52DE", "#FF2D55", "#5AC8FA"];
const $ = (s) => document.querySelector(s);

let counters = load();
let editingId = null;
let pickedColor = COLORS[0];
let pickedMode = "since";

function load() {
  try { return JSON.parse(localStorage.getItem(KEY)) || []; } catch (e) { return []; }
}
function save() {
  try { localStorage.setItem(KEY, JSON.stringify(counters)); } catch (e) {}
}
function isUnlocked() {
  try { return localStorage.getItem(UNLOCK_KEY) === "1"; } catch (e) { return false; }
}
function setUnlocked() {
  try { localStorage.setItem(UNLOCK_KEY, "1"); } catch (e) {}
}

function startOfToday() {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}
function parseDate(s) {
  const p = s.split("-").map(Number);
  return new Date(p[0], p[1] - 1, p[2]);
}
function toInputDate(d) {
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return d.getFullYear() + "-" + m + "-" + day;
}
function daysFor(c) {
  const t = startOfToday();
  const d = parseDate(c.date);
  const diff = Math.round((c.mode === "since" ? t - d : d - t) / 86400000);
  return Math.max(0, diff);
}
function captionFor(c, n) {
  const unit = n === 1 ? "day" : "days";
  return unit + (c.mode === "since" ? " since" : " until");
}

function render() {
  const list = $("#list");
  list.textContent = "";
  $("#empty").hidden = counters.length > 0;

  counters.forEach((c) => {
    const n = daysFor(c);
    const card = document.createElement("button");
    card.className = "card";
    card.style.setProperty("--accent", c.color);

    const emoji = document.createElement("span");
    emoji.className = "emoji";
    emoji.textContent = c.emoji || "📅";

    const mid = document.createElement("span");
    mid.className = "mid";
    const title = document.createElement("span");
    title.className = "title";
    title.textContent = c.title;
    const cap = document.createElement("span");
    cap.className = "cap";
    cap.textContent = captionFor(c, n);
    mid.append(title, cap);

    const num = document.createElement("span");
    num.className = "num";
    num.textContent = n;

    card.append(emoji, mid, num);
    card.addEventListener("click", () => openEditor(c.id));
    list.appendChild(card);
  });
}

function buildSwatches() {
  const box = $("#swatches");
  box.textContent = "";
  COLORS.forEach((hex) => {
    const b = document.createElement("button");
    b.type = "button";
    b.className = "swatch" + (hex === pickedColor ? " on" : "");
    b.style.background = hex;
    b.setAttribute("aria-label", "Color " + hex);
    b.addEventListener("click", () => { pickedColor = hex; buildSwatches(); });
    box.appendChild(b);
  });
}

function setMode(m) {
  pickedMode = m;
  document.querySelectorAll(".seg button").forEach((b) => {
    b.classList.toggle("on", b.dataset.mode === m);
  });
}

function openEditor(id) {
  editingId = id || null;
  const c = id ? counters.find((x) => x.id === id) : null;
  $("#editor-title").textContent = c ? "Edit counter" : "New counter";
  $("#f-title").value = c ? c.title : "";
  $("#f-emoji").value = c ? c.emoji : "📅";
  $("#f-date").value = c ? c.date : toInputDate(new Date());
  pickedColor = c ? c.color : COLORS[0];
  setMode(c ? c.mode : "since");
  buildSwatches();
  $("#delete").hidden = !c;
  $("#editor").showModal();
}

function onAdd() {
  if (!isUnlocked() && counters.length >= CONFIG.freeLimit) {
    $("#price").textContent = CONFIG.price;
    $("#paywall-msg").textContent = "";
    $("#paywall").showModal();
    return;
  }
  openEditor(null);
}

function onSave(e) {
  e.preventDefault();
  const title = $("#f-title").value.trim();
  if (!title) { $("#f-title").focus(); return; }
  const data = {
    title: title,
    emoji: $("#f-emoji").value.trim() || "📅",
    date: $("#f-date").value || toInputDate(new Date()),
    mode: pickedMode,
    color: pickedColor
  };
  if (editingId) {
    const i = counters.findIndex((x) => x.id === editingId);
    if (i >= 0) counters[i] = Object.assign({ id: editingId }, data);
  } else {
    counters.push(Object.assign({ id: String(Date.now()) }, data));
  }
  save();
  render();
  $("#editor").close();
}

function onDelete() {
  if (!editingId) return;
  if (!confirm("Delete this counter?")) return;
  counters = counters.filter((x) => x.id !== editingId);
  save();
  render();
  $("#editor").close();
}

async function sha256Hex(text) {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return Array.from(new Uint8Array(buf)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function onRedeem(e) {
  e.preventDefault();
  const code = $("#f-code").value.trim();
  const msg = $("#paywall-msg");
  if (!code) return;
  try {
    const hash = await sha256Hex(code);
    if (CONFIG.unlockHash && hash === CONFIG.unlockHash.toLowerCase()) {
      setUnlocked();
      $("#paywall").close();
      openEditor(null);
    } else {
      msg.textContent = "That code didn't work.";
    }
  } catch (err) {
    msg.textContent = "Couldn't verify the code on this device.";
  }
}

function init() {
  $("#add").addEventListener("click", onAdd);
  $("#form").addEventListener("submit", onSave);
  $("#cancel").addEventListener("click", () => $("#editor").close());
  $("#delete").addEventListener("click", onDelete);
  document.querySelectorAll(".seg button").forEach((b) => {
    b.addEventListener("click", () => setMode(b.dataset.mode));
  });
  $("#redeem").addEventListener("submit", onRedeem);
  $("#paywall-close").addEventListener("click", () => $("#paywall").close());
  $("#buy").addEventListener("click", () => {
    if (CONFIG.paymentLink) window.open(CONFIG.paymentLink, "_blank", "noopener");
    else $("#paywall-msg").textContent = "Purchases open soon.";
  });

  render();
  // Keep the numbers correct across midnight and when the app is reopened.
  document.addEventListener("visibilitychange", () => { if (!document.hidden) render(); });
  setInterval(render, 60000);

  if ("serviceWorker" in navigator) {
    window.addEventListener("load", () => {
      navigator.serviceWorker.register("sw.js").catch(() => {});
    });
  }
}

init();

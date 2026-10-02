"use client";
import { useEffect, useRef, useState } from "react";
import Link from "next/link";
type Tier = "easy" | "medium" | "hard" | "pro";
type Puzzle = {
  id: string;
  seed: string;
  tier: Tier;
  solution: number[];
  givens: number[];
  proof: number[];
};
type Snapshot = { board: number[]; notes: number[][] };
type Save = Snapshot & {
  version: 1;
  puzzle: Puzzle;
  seconds: number;
  hints: number;
  history: Snapshot[];
};
const letters = "ABCDEFGHIJKLMNOPQRSTUVWXY",
  key = "puzzlecub-mega-v1";
function peers(i: number, j: number) {
  return (
    Math.floor(i / 25) === Math.floor(j / 25) ||
    i % 25 === j % 25 ||
    (Math.floor(i / 125) === Math.floor(j / 125) &&
      Math.floor((i % 25) / 5) === Math.floor((j % 25) / 5))
  );
}
function validSave(s: Save) {
  return (
    s?.version === 1 &&
    s.puzzle?.solution?.length === 625 &&
    s.puzzle.givens?.length === 625 &&
    s.board?.length === 625 &&
    s.notes?.length === 625 &&
    s.board.every((v) => Number.isInteger(v) && v >= -1 && v < 25) &&
    s.puzzle.solution.every((v) => Number.isInteger(v) && v >= 0 && v < 25) &&
    s.puzzle.givens.every((v) => Number.isInteger(v) && v >= -1 && v < 25) &&
    s.notes.every(
      (n) =>
        Array.isArray(n) &&
        n.every((v) => Number.isInteger(v) && v >= 0 && v < 25),
    ) &&
    Number.isFinite(s.seconds) &&
    s.seconds >= 0 &&
    Array.isArray(s.history) &&
    s.history.length <= 100 &&
    s.history.every(
      (h) =>
        h.board?.length === 625 &&
        h.notes?.length === 625 &&
        h.board.every((v) => Number.isInteger(v) && v >= -1 && v < 25) &&
        h.notes.every(
          (n) =>
            Array.isArray(n) &&
            n.every((v) => Number.isInteger(v) && v >= 0 && v < 25),
        ),
    ) &&
    ["easy", "medium", "hard", "pro"].includes(s.puzzle.tier) &&
    Number.isInteger(s.hints) &&
    s.hints >= 0 &&
    s.puzzle.givens.every(
      (v, i) => v < 0 || (s.board[i] === v && s.puzzle.solution[i] === v),
    )
  );
}
export default function Mega({ week }: { week?: string }) {
  const [save, setSave] = useState<Save | null>(null),
    [tier, setTier] = useState<Tier>("medium"),
    [selected, setSelected] = useState(0),
    [noteMode, setNoteMode] = useState(false),
    [paused, setPaused] = useState(false),
    [focusBox, setFocusBox] = useState(false),
    [zoom, setZoom] = useState(false),
    [contrast, setContrast] = useState(false),
    [busy, setBusy] = useState(true),
    [message, setMessage] = useState(""),
    [help, setHelp] = useState(false),
    [ready, setReady] = useState(false),
    [completed, setCompleted] = useState(0);
  const worker = useRef<Worker | null>(null),
    cellRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const storageKey = week ? key + "-weekly" : key;
  const won =
    !!save && save.board.every((v, i) => v === save.puzzle.solution[i]);
  function request(newTier: Tier, seed: string) {
    setBusy(true);
    setMessage("Creating a uniquely solvable board…");
    worker.current?.postMessage({ tier: newTier, seed });
  }
  useEffect(() => {
    const w = new Worker("/workers/mega-engine.mjs", { type: "module" });
    worker.current = w;
    w.onmessage = ({ data }) => {
      if (data.error) {
        setMessage(data.error);
        setBusy(false);
        return;
      }
      const p = data.puzzle as Puzzle;
      setSave({
        version: 1,
        puzzle: p,
        board: [...p.givens],
        notes: Array.from({ length: 625 }, () => []),
        seconds: 0,
        hints: 0,
        history: [],
      });
      setTier(p.tier);
      setSelected(p.givens.findIndex((v) => v < 0));
      setPaused(false);
      setMessage("Ready. Every row, column and 5×5 box uses A–Y once.");
      setBusy(false);
    };
    w.onerror = () => {
      setBusy(false);
      setMessage("The puzzle engine could not load. Refresh to retry.");
    };
    let cancelled = false;
    queueMicrotask(() => {
      if (cancelled) return;
      try {
        const raw = localStorage.getItem(storageKey);
        if (raw) {
          const s = JSON.parse(raw);
          if (!validSave(s)) throw Error();
          if (!week || s.puzzle.seed === week) {
            setSave(s);
            setTier(s.puzzle.tier);
            setBusy(false);
          } else w.postMessage({ tier: "medium", seed: week });
        } else
          w.postMessage({ tier: "medium", seed: week ?? crypto.randomUUID() });
        setCompleted(
          JSON.parse(localStorage.getItem("puzzlecub-mega-completed") ?? "[]")
            .length,
        );
      } catch {
        setMessage("Saved progress could not be read. Starting a new board.");
        w.postMessage({ tier: "medium", seed: week ?? crypto.randomUUID() });
      }
      setReady(true);
    });
    return () => {
      cancelled = true;
      w.terminate();
    };
  }, [storageKey, week]);
  useEffect(() => {
    if (!save || !ready) return;
    try {
      localStorage.setItem(storageKey, JSON.stringify(save));
    } catch {
      queueMicrotask(() =>
        setMessage(
          "This browser cannot save progress. Keep this tab open; progress may be lost when it closes.",
        ),
      );
    }
  }, [save, ready, storageKey]);
  useEffect(() => {
    if (paused || busy || help || won) return;
    const id = setInterval(() => {
      if (document.visibilityState === "visible")
        setSave((s) => (s ? { ...s, seconds: s.seconds + 1 } : s));
    }, 1000);
    return () => clearInterval(id);
  }, [paused, busy, help, won]);
  useEffect(() => {
    if (!won || !save) return;
    try {
      const ids: string[] = JSON.parse(
        localStorage.getItem("puzzlecub-mega-completed") ?? "[]",
      );
      if (!ids.includes(save.puzzle.id)) {
        ids.push(save.puzzle.id);
        localStorage.setItem("puzzlecub-mega-completed", JSON.stringify(ids));
        queueMicrotask(() => setCompleted(ids.length));
      }
    } catch {}
  }, [won, save]);
  function select(i: number) {
    setSelected(i);
    requestAnimationFrame(() => cellRefs.current[i]?.focus());
  }
  function place(v: number) {
    if (!save || busy || paused || won || save.puzzle.givens[selected] >= 0)
      return;
    const board = [...save.board],
      notes = save.notes.map((n) => [...n]);
    if (noteMode && v >= 0) {
      if (board[selected] >= 0) {
        setMessage("Erase this letter before adding notes.");
        return;
      }
      notes[selected] = notes[selected].includes(v)
        ? notes[selected].filter((n) => n !== v)
        : [...notes[selected], v].sort((a, b) => a - b);
    } else {
      board[selected] = v;
      notes[selected] = [];
    }
    setSave({
      ...save,
      board,
      notes,
      history: [
        ...save.history,
        { board: save.board, notes: save.notes },
      ].slice(-100),
    });
    setMessage("");
  }
  function hint() {
    if (!save || save.puzzle.tier === "pro" || won || paused || busy) return;
    if (save.board[selected] >= 0) {
      setMessage("Select an empty cell for a hint.");
      return;
    }
    const board = [...save.board],
      notes = save.notes.map((n) => [...n]);
    board[selected] = save.puzzle.solution[selected];
    notes[selected] = [];
    setSave({
      ...save,
      board,
      notes,
      hints: save.hints + 1,
      history: [
        ...save.history,
        { board: save.board, notes: save.notes },
      ].slice(-100),
    });
    setMessage(
      `Hint: row ${Math.floor(selected / 25) + 1}, column ${(selected % 25) + 1} is ${letters[board[selected]]}.`,
    );
  }
  function newGame() {
    if (
      save &&
      !won &&
      !window.confirm(
        "Start a new puzzle? This replaces the saved Mega board in this slot.",
      )
    )
      return;
    request(week ? "medium" : tier, week ?? crypto.randomUUID());
  }
  const shown = Array.from({ length: 625 }, (_, i) => i).filter(
    (i) =>
      !focusBox ||
      (Math.floor(i / 125) === Math.floor(selected / 125) &&
        Math.floor((i % 25) / 5) === Math.floor((selected % 25) / 5)),
  );
  return (
    <div className={`mega-game ${contrast ? "high-contrast" : ""}`}>
      <div className="mega-controls">
        <div className="game-toolbar mega-topbar">
          <label>
            Difficulty{" "}
            <select
              value={tier}
              disabled={busy || !!week}
              onChange={(e) => setTier(e.target.value as Tier)}
            >
              {["easy", "medium", "hard", "pro"].map((t) => (
                <option key={t}>{t}</option>
              ))}
            </select>
          </label>
          <button
            className="button secondary"
            disabled={busy}
            onClick={newGame}
          >
            New puzzle
          </button>
          <button
            className="button secondary"
            disabled={busy || won}
            onClick={() => setPaused(!paused)}
          >
            {paused ? "Resume" : "Pause"}
          </button>
          <button className="button secondary" onClick={() => setHelp(!help)}>
            {help ? "Close guide" : "How to play"}
          </button>
          <span className="game-clock">
            {Math.floor((save?.seconds ?? 0) / 60)}:
            {String((save?.seconds ?? 0) % 60).padStart(2, "0")}
          </span>
        </div>
        {help && (
          <section className="inline-guide">
            <h2>Twenty-five letters. Three simple rules.</h2>
            <p>
              Each row, column and bold 5×5 box contains A–Y once. There is no
              hidden word. Select a cell, then type a letter or use the letter
              tray. Arrow keys move, Backspace erases, and Space switches notes.
              Notes are your own pencil marks.
            </p>
            <p>
              Try focusing on one 5×5 box to study its letters. The box selector
              moves around the whole puzzle. Hints reveal a selected empty cell;
              Pro keeps hints disabled. Difficulty controls clue density in this
              first edition, not a certified human solving-technique rating.
            </p>
            <Link href="/learn/mega-guide">Read the full Mega guide →</Link>
          </section>
        )}
        <div className="board-options">
          <button
            aria-pressed={focusBox}
            onClick={() => setFocusBox(!focusBox)}
          >
            {focusBox ? "Show full board" : "Focus on a box"}
          </button>
          {focusBox ? (
            <label className="box-picker">
              Box
              <select
                aria-label="Choose a 5 by 5 box"
                value={
                  Math.floor(selected / 125) * 5 +
                  Math.floor((selected % 25) / 5)
                }
                onChange={(e) =>
                  setSelected(
                    Math.floor(Number(e.target.value) / 5) * 125 +
                      (Number(e.target.value) % 5) * 5,
                  )
                }
              >
                {Array.from({ length: 25 }, (_, i) => (
                  <option value={i} key={i}>
                    Box {i + 1}
                  </option>
                ))}
              </select>
            </label>
          ) : (
            <button aria-pressed={zoom} onClick={() => setZoom(!zoom)}>
              {zoom ? "Normal letters" : "Larger letters"}
            </button>
          )}
          <button
            aria-pressed={contrast}
            onClick={() => setContrast(!contrast)}
          >
            High contrast
          </button>
          <span>
            {save?.board.filter((v) => v >= 0).length ?? 0}/625 filled ·{" "}
            {save?.puzzle.tier ?? tier} · {completed} completed
          </span>
        </div>
        <div className="letter-tray" aria-label="Letter entry">
          {Array.from(letters).map((c, v) => (
            <button
              key={c}
              disabled={busy || paused || won}
              onClick={() => place(v)}
            >
              <strong>{c}</strong>
              <small>
                {Math.max(
                  0,
                  25 - (save?.board.filter((x) => x === v).length ?? 0),
                )}{" "}
                left
              </small>
            </button>
          ))}
        </div>
        <div className="game-toolbar mega-actions">
          <button
            aria-pressed={noteMode}
            onClick={() => setNoteMode(!noteMode)}
          >
            Notes {noteMode ? "on" : "off"} (Space)
          </button>
          <button
            disabled={!save?.history.length || busy || paused || won}
            onClick={() => {
              if (!save) return;
              const last = save.history.at(-1)!;
              setSave({ ...save, ...last, history: save.history.slice(0, -1) });
            }}
          >
            Undo
          </button>
          <button disabled={busy || paused || won} onClick={() => place(-1)}>
            Erase
          </button>
          <button
            disabled={save?.puzzle.tier === "pro" || busy || paused || won}
            onClick={hint}
          >
            Hint {save?.puzzle.tier === "pro" ? "· unavailable in Pro" : ""}
          </button>
        </div>
        <p className="game-status" role="status">
          {message ||
            "Saved automatically on this device. Select a cell to begin."}
        </p>
        {won && (
          <section className="win-card" role="status">
            <span className="tag">625 CELLS. ONE SATISFYING FINISH.</span>
            <h2>You found the big picture.</h2>
            <p>
              {save?.hints
                ? `${save.hints} hints used.`
                : "Solved without revealing hints."}{" "}
              Your completed puzzle is saved.
            </p>
            <div className="button-row">
              <button className="button primary" onClick={newGame}>
                {week ? "Replay weekly puzzle" : "Play again"}
              </button>
              <button
                className="button secondary"
                onClick={async () => {
                  const text = `I solved Alphadoku Mega (${save?.puzzle.tier}) on PuzzleCub! ${week ? location.href : location.origin + "/alphadoku/mega"}`;
                  try {
                    await navigator.clipboard.writeText(text);
                    setMessage("Result copied.");
                  } catch {
                    setMessage(text);
                  }
                }}
              >
                Copy result
              </button>
            </div>
          </section>
        )}
        <p className="small-note">
          Unlimited play. No purchases. Hints are free during the launch beta.
          Notes and saves stay in this browser; clearing site data removes them.
          Pro disables revealing hints. Mega’s initial tiers vary clue density.
        </p>
      </div>
      <div className="mega-stage">
        {busy ? (
          <div className="game-loading" role="status">
            Creating your puzzle…
          </div>
        ) : paused ? (
          <div className="game-loading">
            <h2>A moment to breathe.</h2>
            <button className="button primary" onClick={() => setPaused(false)}>
              Resume puzzle
            </button>
          </div>
        ) : (
          save && (
            <div className="board-scroll">
              <div
                role="grid"
                aria-label="Mega Sudoku, 25 rows and 25 columns"
                aria-rowcount={25}
                aria-colcount={25}
                className={`mega-board ${focusBox ? "focused" : ""} ${zoom ? "zoomed" : ""}`}
                style={{
                  gridTemplateColumns: `repeat(${focusBox ? 5 : 25},minmax(0,1fr))`,
                }}
                onKeyDown={(e) => {
                  if (e.ctrlKey || e.metaKey || e.altKey) return;
                  let next = selected;
                  if (e.key === "ArrowLeft") next = Math.max(0, selected - 1);
                  else if (e.key === "ArrowRight")
                    next = Math.min(624, selected + 1);
                  else if (e.key === "ArrowUp")
                    next = Math.max(0, selected - 25);
                  else if (e.key === "ArrowDown")
                    next = Math.min(624, selected + 25);
                  else if (e.key === " ") {
                    setNoteMode(!noteMode);
                    e.preventDefault();
                    return;
                  } else if (e.key === "Backspace" || e.key === "Delete") {
                    place(-1);
                    e.preventDefault();
                    return;
                  } else if (
                    e.key.length === 1 &&
                    letters.includes(e.key.toUpperCase())
                  ) {
                    place(letters.indexOf(e.key.toUpperCase()));
                    e.preventDefault();
                    return;
                  } else return;
                  e.preventDefault();
                  select(next);
                }}
              >
                {Array.from(new Set(shown.map((i) => Math.floor(i / 25)))).map(
                  (row) => (
                    <div role="row" key={row} style={{ display: "contents" }}>
                      {shown
                        .filter((i) => Math.floor(i / 25) === row)
                        .map((i) => {
                          const v = save.board[i],
                            given = save.puzzle.givens[i] >= 0,
                            conflict =
                              v >= 0 &&
                              save.board.some(
                                (x, j) => i !== j && x === v && peers(i, j),
                              );
                          return (
                            <button
                              role="gridcell"
                              aria-rowindex={Math.floor(i / 25) + 1}
                              aria-colindex={(i % 25) + 1}
                              aria-selected={i === selected}
                              aria-readonly={given}
                              aria-label={`Row ${Math.floor(i / 25) + 1}, column ${(i % 25) + 1}, ${v < 0 ? "empty" : letters[v]}${given ? ", given" : ""}${conflict ? ", conflict" : ""}${save.notes[i].length ? ", notes " + save.notes[i].map((n) => letters[n]).join(" ") : ""}`}
                              tabIndex={i === selected ? 0 : -1}
                              ref={(el) => {
                                cellRefs.current[i] = el;
                              }}
                              key={i}
                              onClick={() => setSelected(i)}
                              className={`mega-cell ${given ? "given" : ""} ${i === selected ? "selected" : ""} ${peers(i, selected) ? "peer" : ""} ${v >= 0 && v === save.board[selected] ? "same" : ""} ${conflict ? "conflict" : ""}`}
                              style={{
                                borderRightWidth: i % 5 === 4 ? 2 : 1,
                                borderBottomWidth:
                                  Math.floor(i / 25) % 5 === 4 ? 2 : 1,
                              }}
                            >
                              {v >= 0 ? (
                                letters[v]
                              ) : save.notes[i].length ? (
                                <small>
                                  {focusBox || zoom
                                    ? save.notes[i]
                                        .map((n) => letters[n])
                                        .join(" ")
                                    : "·".repeat(
                                        Math.min(3, save.notes[i].length),
                                      )}
                                </small>
                              ) : (
                                ""
                              )}
                            </button>
                          );
                        })}
                    </div>
                  ),
                )}
              </div>
            </div>
          )
        )}
      </div>
    </div>
  );
}

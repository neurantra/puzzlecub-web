"use client";
import Link from "next/link";
import { useEffect, useState } from "react";
export function ContinuePlaying() {
  const [saved, setSaved] = useState<string[]>([]);
  useEffect(() => {
    try {
      const result: string[] = [];
      if (localStorage.getItem("puzzlecub-mega-v1")) result.push("mega");
      if (
        Object.keys(localStorage).some(
          (k) =>
            k.includes("alphadoku") &&
            k.endsWith("alphadoku.session.v1") &&
            localStorage.getItem(k),
        )
      )
        result.push("classic");
      queueMicrotask(() => setSaved(result));
    } catch {}
  }, []);
  return saved.length ? (
    <div className="continue-strip">
      <span>Pick up where you left off</span>
      {saved.map((m) => (
        <Link href={`/alphadoku/${m}`} key={m}>
          Continue {m} →
        </Link>
      ))}
    </div>
  ) : null;
}
export function TryDeduction() {
  const [answer, setAnswer] = useState("");
  return (
    <div className="try-card">
      <div>
        <span className="tag">A LITTLE WARM-UP</span>
        <h2>One space. One possibility.</h2>
        <p>This row uses A to I exactly once. Which letter is missing?</p>
        <div className="mini-row" aria-label="A B C D blank F G H I">
          {"ABCD?FGHI".split("").map((x, i) => (
            <span key={i} className={x === "?" ? "missing" : ""}>
              {x === "?" && answer === "E" ? "E" : x}
            </span>
          ))}
        </div>
        <div className="choices">
          {["E", "G", "J"].map((c) => (
            <button
              aria-pressed={answer === c}
              onClick={() => setAnswer(c)}
              key={c}
            >
              {c}
            </button>
          ))}
        </div>
        <p className="feedback" role="status">
          {answer
            ? answer === "E"
              ? "Exactly. E is the only missing letter. In a full puzzle, also check the column and box."
              : "Try again. G is already in this row, and J is outside A–I."
            : "No timer. Take a moment."}
        </p>
      </div>
      <Link href="/learn/one-choice">Learn your first technique ↗</Link>
    </div>
  );
}

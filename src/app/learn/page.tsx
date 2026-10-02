import Link from "next/link";
import { WebShell } from "../_components/WebShell";
import techniques from "../_lib/techniques.json";
export const metadata = {
  title: "Learn letter Sudoku — Illustrated techniques & game guides",
};
export default function Page() {
  return (
    <WebShell>
      <main id="main" className="web-section">
        <span className="tag">MAKE YOUR NEXT MOVE MAKE SENSE</span>
        <h1 className="page-title">
          A little logic
          <br />
          goes a long way.
        </h1>
        <p className="intro">
          Letters change the look, not the logic. Learn what a deduction means,
          see a candidate example, and bring it back to your board. Start with
          singles; move on to pairs and chains when you’re ready.
        </p>
        <div className="challenge-links">
          <Link href="/learn/getting-started">
            <span className="tag">START HERE</span>
            <h2>Your first Classic puzzle</h2>
            <p>
              The Sudoku rules, the hidden line, and what each control does.
            </p>
            <strong>Read the guide →</strong>
          </Link>
          <Link href="/learn/mega-guide">
            <span className="tag">THINK BIGGER</span>
            <h2>Your first Mega puzzle</h2>
            <p>
              Navigate A–Y, manage notes, and take a large board one box at a
              time.
            </p>
            <strong>Read the guide →</strong>
          </Link>
        </div>
        <div className="techniques-grid">
          {techniques.map((t, i) => (
            <Link key={t.slug} href={`/learn/${t.slug}`}>
              <span>
                {String(i + 1).padStart(2, "0")} · {t.alias}
              </span>
              <h2>{t.name}</h2>
              <p>{t.rule}</p>
            </Link>
          ))}
        </div>
        <div className="button-row">
          <Link className="button secondary" href="/learn/worked-example">
            Work through a deduction →
          </Link>
        </div>
      </main>
    </WebShell>
  );
}

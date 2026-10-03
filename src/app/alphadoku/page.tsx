import Link from "next/link";
import { WebShell, ModeCards, AlphaIdentity } from "../_components/WebShell";
import { ContinuePlaying, TryDeduction } from "../_components/Discovery";
export const metadata = {
  title: "Alphadoku — Play Classic & Mega letter Sudoku",
};
export default function Page() {
  return (
    <WebShell>
      <main id="main" className="web-section">
        <ContinuePlaying />
        <AlphaIdentity />
        <h1 className="page-title">
          Letters. Logic.
          <br />A little discovery.
        </h1>
        <p className="intro">
          Classic hides a nine-letter word or phrase in one row or column. Mega
          is a larger, pure alphabet Sudoku: A–Y, with no hidden line. Both are
          free to play, with progress saved in this browser. Mega needs a
          desktop or laptop screen.
        </p>
        <ModeCards />
        <div className="button-row">
          <Link className="button secondary" href="/learn/getting-started">
            How to play
          </Link>
          <Link className="text-link" href="/challenges">
            Daily & weekly challenges →
          </Link>
        </div>
        <section className="challenge-band">
          <div>
            <span className="tag">SOMETHING TO COME BACK TO</span>
            <h2>
              A fresh puzzle.
              <br />A familiar little ritual.
            </h2>
            <p>
              Daily Classic. Weekly Mega. Shared challenges with no race to the
              finish. Missed a day? The archive is yours to explore.
            </p>
            <Link className="button primary" href="/challenges">
              Explore challenges ↗
            </Link>
          </div>
          <div className="challenge-illustration">
            <span className="calendar-label">YOUR NEXT SMALL VICTORY</span>
            <div className="calendar-cells">
              {[
                "M",
                "T",
                "W",
                "T",
                "F",
                "S",
                "S",
                "✓",
                "✓",
                "✦",
                "·",
                "·",
                "·",
                "·",
              ].map((x, i) => (
                <span key={i} className={i === 9 ? "today" : ""}>
                  {x}
                </span>
              ))}
            </div>
            <p>Make time for a little thinking.</p>
          </div>
        </section>
        <section className="web-section">
          <TryDeduction />
        </section>
        <section className="web-section learning-section">
          <div>
            <span className="tag">GET BETTER, ONE “AHA” AT A TIME</span>
            <h2>
              Good puzzles teach you
              <br />
              how to see differently.
            </h2>
            <p>
              Start with a single missing letter. Learn to spot pairs, follow
              candidates, and make a deduction you can explain.
            </p>
            <Link className="text-link" href="/learn">
              Explore the technique library →
            </Link>
          </div>
          <div className="lesson-stack">
            {[
              [
                "01",
                "one-choice",
                "One choice",
                "Find the only letter that fits.",
              ],
              [
                "02",
                "hidden-single",
                "Hidden single",
                "Find the only place a letter can go.",
              ],
              [
                "03",
                "naked-pair",
                "Naked pair",
                "Two cells can tell you more than one.",
              ],
            ].map(([n, url, title, desc]) => (
              <Link href={`/learn/${url}`} key={n}>
                <span>{n}</span>
                <div>
                  <h3>{title}</h3>
                  <p>{desc}</p>
                </div>
                <b>↗</b>
              </Link>
            ))}
          </div>
        </section>
      </main>
    </WebShell>
  );
}

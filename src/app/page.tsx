import type { Metadata } from "next";
import Link from "next/link";
import Image from "next/image";
import { WebShell, ModeCards } from "./_components/WebShell";
import { ContinuePlaying, TryDeduction } from "./_components/Discovery";
export const metadata: Metadata = {
  alternates: { canonical: "https://puzzlecub.com/" },
};
export default function Home() {
  return (
    <WebShell>
      <main id="main">
        <ContinuePlaying />
        <section className="games-welcome" id="games">
          <span className="tag">A LITTLE THOUGHT. A BRIGHT DISCOVERY.</span>
          <h1>
            Make time for <em>play.</em>
          </h1>
          <p>
            Ancient strategy. A fresh twist on Sudoku. Find your next good
            challenge.
          </p>
          <div className="game-collection">
            <Link href="/chaturang" className="collection-card chaturang-card">
              <div className="collection-art court-art" aria-hidden="true">
                <Image
                  src="/chaturang/court.png"
                  alt=""
                  fill
                  sizes="(max-width: 700px) 100vw, 50vw"
                  priority
                />
                <span className="game-badge">NEW ON THE WEB</span>
              </div>
              <div className="collection-copy">
                <span className="tag">ANCIENT STRATEGY · PLAY AGAINST AI</span>
                <h2>Chaturang</h2>
                <p>
                  Enter the royal court. Choose your side and meet your rival in
                  the Indian ancestor of chess.
                </p>
                <strong>
                  Play Chaturang <span>↗</span>
                </strong>
              </div>
            </Link>
            <Link href="/alphadoku" className="collection-card alphadoku-card">
              <div className="collection-art letter-art" aria-hidden="true">
                <div className="collection-letter-grid">
                  {"ALGORITHM".split("").map((c, i) => (
                    <span className={i > 2 && i < 6 ? "lit" : ""} key={i}>
                      {c}
                    </span>
                  ))}
                </div>
                <span className="game-badge">CLASSIC + MEGA</span>
              </div>
              <div className="collection-copy">
                <span className="tag">LETTER SUDOKU · YOUR DAILY AHA</span>
                <h2>Alphadoku</h2>
                <p>
                  Nine letters. One hidden line. Or stretch out with a 25 × 25
                  Mega board. All logic, at your pace.
                </p>
                <strong>
                  Play Alphadoku <span>↗</span>
                </strong>
              </div>
            </Link>
          </div>
          <p className="games-note">
            Free to play · No account needed · No downloads
          </p>
        </section>
        <section className="web-section">
          <div className="section-heading">
            <div>
              <span className="tag">MEET ALPHADOKU</span>
              <h2>Find your kind of challenge.</h2>
            </div>
            <p>
              Two sizes. The same satisfying logic.
              <br />
              Choose a quick start or a longer adventure.
            </p>
          </div>
          <ModeCards />
        </section>
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
        <section className="app-banner">
          <div>
            <span className="tag">TAKE A LITTLE PLAY WITH YOU</span>
            <h2>More worlds. Same curiosity.</h2>
            <p>
              Discover our independent mobile games, from map puzzles to mazes
              and strategy.
            </p>
          </div>
          <Link className="button secondary" href="/mobile-apps">
            Explore our apps ↗
          </Link>
        </section>
      </main>
    </WebShell>
  );
}

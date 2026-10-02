import Link from "next/link";
import { WebShell, ModeCards } from "./_components/WebShell";
import { ContinuePlaying, TryDeduction } from "./_components/Discovery";
export default function Home() {
  return (
    <WebShell>
      <main id="main">
        <ContinuePlaying />
        <section className="hero">
          <div className="hero-copy">
            <span className="tag">YOUR DAILY DOSE OF “GOT IT.”</span>
            <h1>
              A little thought.
              <br />A <em>bright</em> discovery.
            </h1>
            <p>
              Settle into something satisfying. Original letter puzzles to play,
              learn, and come back to. Right here in your browser.
            </p>
            <div className="button-row">
              <Link className="button primary" href="/challenges">
                Play today’s challenge <span>↗</span>
              </Link>
              <Link className="text-link" href="/alphadoku">
                Find your puzzle →
              </Link>
            </div>
            <div className="hero-note">
              <span>✦</span> Unlimited play. No account. Your pace.
            </div>
          </div>
          <div className="hero-visual" aria-hidden="true">
            <span className="orbit orbit-one">A fresh perspective</span>
            <div className="hero-board">
              {"ALGORITHM".split("").map((c, i) => (
                <span className={[3, 4, 5].includes(i) ? "lit" : ""} key={i}>
                  {c}
                </span>
              ))}
            </div>
            <div className="floating-note">
              <span>✧</span> That’s the missing piece.
            </div>
            <span className="orbit orbit-two">
              Nine letters. One hidden line.
            </span>
          </div>
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

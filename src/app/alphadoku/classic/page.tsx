import Link from "next/link";
import { WebShell, AlphaIdentity } from "../../_components/WebShell";
import { validDay } from "../../_lib/challenges";
export const metadata = {
  title: "Play Classic Alphadoku — 9×9 letter Sudoku",
  description:
    "Play unlimited Classic Alphadoku in your browser. Nine unique letters, one hidden line, four difficulty levels, notes, hints and save/resume.",
};
export default async function Page({
  searchParams,
}: {
  searchParams: Promise<{ day?: string }>;
}) {
  const { day } = await searchParams;
  const challenge = day && validDay(day) ? day : null;
  return (
    <WebShell>
      <main id="main" className="play-page classic-play-page">
        <div className="play-heading">
          <AlphaIdentity />
          <nav>
            <Link href="/alphadoku/mega">Try Mega ↗</Link>
            <Link href="/learn/getting-started">How to play</Link>
          </nav>
        </div>
        <h1>
          Classic{" "}
          {challenge
            ? `· ${challenge} daily challenge`
            : "· Nine letters. One hidden line."}
        </h1>
        <p>
          Unlimited puzzles and hints in Easy–Hard. Pro stays unassisted.
          Progress saves in this browser.{" "}
          {challenge &&
            "Select Medium and start a new puzzle for today’s shared board. Challenge progress has its own save slot."}
        </p>
        <div className="classic-mobile-bar">
          <Link href="/alphadoku">← PuzzleCub</Link>
          <strong>Classic Alphadoku</strong>
          <Link href="/learn/getting-started">Guide</Link>
          <Link href="/privacy">Privacy</Link>
        </div>
        <iframe
          title="Playable Classic Alphadoku"
          className="classic-frame"
          src={`/classic-game/index.html${challenge ? "?day=" + challenge : ""}`}
          allow="fullscreen"
        />
        <section className="play-explainer">
          <h2>A familiar puzzle, with a hidden word.</h2>
          <p>
            Every row, column and 3×3 box uses each of the nine target letters
            once. Exactly one complete row or column spells the target in order.
            Easy reveals that line; Medium fills it after you identify it. In
            Hard, confirm the line and fill it yourself. Pro removes revealing
            hints.
          </p>
          <Link href="/learn">Stuck? Learn a solving technique →</Link>
          <p className="small-note">
            Keep this tab open to keep playing if your connection drops.
            Clearing browser storage removes local saves. No purchases or
            accounts.
          </p>
        </section>
      </main>
    </WebShell>
  );
}

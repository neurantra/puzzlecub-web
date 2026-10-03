import Link from "next/link";
import { WebShell } from "../_components/WebShell";
import { AdPlacement } from "../_components/Advertising";
export const metadata = {
  title: "Play Chaturang — Free ancient Indian chess against AI",
  description:
    "Enter the royal court and play Chaturang free against AI. Three difficulty levels, sculpted pieces, hints, and the same game flow as our mobile app. No account needed.",
  alternates: { canonical: "https://puzzlecub.com/chaturang" },
};
export default function Chaturang() {
  return (
    <WebShell>
      <main id="main" className="play-page chaturang-play-page">
        <div className="play-heading">
          <Link href="/#games">← All games</Link>
          <nav>
            <Link href="#chaturang-rules">How to play</Link>
            <Link href="/privacy">Privacy</Link>
          </nav>
        </div>
        <h1>
          Chaturang <span>· Enter the court.</span>
        </h1>
        <p>The Indian ancestor of chess. Free, unlimited games against AI.</p>
        <iframe
          title="Playable Chaturang"
          className="chaturang-frame"
          src="/chaturang-game/index.html"
          allow="fullscreen; autoplay"
        />
        <section className="play-explainer" id="chaturang-rules">
          <span className="tag">AN ANCIENT BOARD. A NEW RIVALRY.</span>
          <h2>Your place at the court.</h2>
          <p>
            Choose an AI level, pick a royal card to reveal your side, and make
            your opening move. Tap a piece to see its legal moves, then tap a
            destination. The in-game “Learn to play” guide explains every piece
            and the rules.
          </p>
          <p>
            The elephant and counsellor move differently from their modern chess
            counterparts. Pawns advance one square, there is no castling, and
            each king has a special knight leap available once per game when
            permitted by the rules. Checkmate wins; the game also handles draws
            and optional time and move limits.
          </p>
          <p>
            Hints and rematches are free. Settings, local statistics, earned
            coins, and cosmetic choices stay in this browser; there are no
            accounts, purchases, or online opponents. An unfinished match ends
            when you reload or leave the game page.
          </p>
          <Link href="/alphadoku">
            In the mood for a puzzle? Try Alphadoku →
          </Link>
        </section>
        <AdPlacement gameplay />
      </main>
    </WebShell>
  );
}

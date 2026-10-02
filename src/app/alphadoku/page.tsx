import Link from "next/link";
import { WebShell, ModeCards, AlphaIdentity } from "../_components/WebShell";
export const metadata = {
  title: "Alphadoku — Play Classic & Mega letter Sudoku",
};
export default function Page() {
  return (
    <WebShell>
      <main id="main" className="web-section">
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
      </main>
    </WebShell>
  );
}

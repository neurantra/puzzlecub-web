import { WebShell } from "../_components/WebShell";
export const metadata = {
  title: "About PuzzleCub — Independent puzzles by Neurantra",
};
export default function Page() {
  return (
    <WebShell>
      <main id="main" className="article">
        <span className="tag">A LITTLE THOUGHT. A BRIGHT DISCOVERY.</span>
        <h1>
          Made for the moment
          <br />
          something clicks.
        </h1>
        <p>
          PuzzleCub is an independent browser-game collection by Neurantra LLC.
          We make puzzles built around simple rules, clear feedback, and the
          pleasure of figuring something out.
        </p>
        <h2>Our first browser game: Alphadoku</h2>
        <p>
          Classic turns Sudoku into a word-and-logic puzzle, with nine distinct
          letters and one hidden line. Mega offers a quieter, larger challenge
          using A–Y in a 25×25 grid. Both are unlimited, with no account or
          purchase required.
        </p>
        <h2>Web games and mobile apps</h2>
        <p>
          The browser collection lives at puzzlecub.com. Our mobile app
          directory lives at puzzlecub.app. The existing PuzzleCub
          mobile app and sibling games remain separate products; their purchases
          and saved progress do not transfer to this website.
        </p>
        <h2>How we check our puzzles</h2>
        <p>
          Classic uses the same constraint engine as our mobile game, checking
          Sudoku and the hidden-line rule together. Mega accepts clue removals
          only with a constructive uniqueness proof. Its initial difficulty
          levels describe clue density. Our English word library contains 2,671
          validated isogram targets; its editorial review was AI-assisted, not
          independent human review of every entry.
        </p>
        <h2>Help us make it better</h2>
        <p>
          Found an awkward phrase, a confusing control, or an accessibility
          problem? Tell us the mode, difficulty, browser, and what happened.
          Please do not send payment information or passwords.
        </p>
        <p>
          <a href="mailto:hello@neurantra.com?subject=PuzzleCub%20web%20feedback">
            hello@neurantra.com
          </a>
        </p>
      </main>
    </WebShell>
  );
}

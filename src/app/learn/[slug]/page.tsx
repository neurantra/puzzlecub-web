import Link from "next/link";
import { notFound } from "next/navigation";
import { WebShell } from "../../_components/WebShell";
import { TryDeduction } from "../../_components/Discovery";
import techniques from "../../_lib/techniques.json";
export function generateStaticParams() {
  return [
    ...techniques.map((t) => ({ slug: t.slug })),
    ...["getting-started", "mega-guide", "worked-example"].map((slug) => ({
      slug,
    })),
  ];
}
export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  return {
    title: `${techniques.find((t) => t.slug === slug)?.name ?? { "getting-started": "How to play Classic", "mega-guide": "How to play Mega", "worked-example": "A worked Sudoku deduction" }[slug] ?? "Learn"} — PuzzleCub`,
  };
}
export default async function Page({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const t = techniques.find((t) => t.slug === slug);
  if (!t && !["getting-started", "mega-guide", "worked-example"].includes(slug))
    notFound();
  return (
    <WebShell>
      <main id="main" className="article">
        <Link href="/learn">← All guides and techniques</Link>
        {t ? (
          <>
            <span className="tag" style={{ marginTop: 32 }}>
              {t.alias}
            </span>
            <h1>{t.name}</h1>
            <p>{t.rule}</p>
            <div className="lesson-example">
              <strong>A letter-based example</strong>
              <p>{t.example}</p>
            </div>
            {t.slug.includes("pair") ? (
              <div
                className="note-pair"
                aria-label="Two candidate cells, each containing A and B"
              >
                <span>A B</span>
                <span>A B</span>
                <span>?</span>
              </div>
            ) : t.slug === "one-choice" ? (
              <TryDeduction />
            ) : (
              <div
                className="note-pair"
                aria-label="Candidate notation example"
              >
                <span>A B</span>
                <span>B C</span>
                <span>C D</span>
              </div>
            )}
            <h2>Use it on your board</h2>
            <ol>
              <li>
                Choose a row, column or box to inspect. A “unit” means any one
                of these.
              </li>
              <li>
                Check legal candidates against every placed letter. Pencil notes
                are reminders, not proof: missing or stale notes can hide a
                possibility.
              </li>
              <li>
                Verify every condition in the rule above before making an
                elimination. A pattern that almost matches is not enough.
              </li>
              <li>
                Update the affected notes, then scan for a newly forced letter.
                A technique often opens the way to a much simpler next move.
              </li>
            </ol>
            <h2>Classic and Mega</h2>
            <p>
              The candidate rule applies at both board sizes. Classic adds the
              hidden-line constraint; Mega uses only rows, columns and 5×5
              boxes. A larger board has more candidates, so focus on one unit at
              a time.
            </p>
            <p>
              These examples explain deductions, not a promise that every
              generated puzzle requires this technique. In particular, Mega’s
              launch tiers describe clue density.
            </p>
          </>
        ) : slug === "getting-started" ? (
          <>
            <h1>Your first Classic puzzle</h1>
            <p>
              Alphadoku starts with a word or two-word phrase containing nine
              different letters. Spaces separate the words; they do not occupy
              cells. ALGORITHM, for example, supplies A, L, G, O, R, I, T, H and
              M.
            </p>
            <h2>The three Sudoku rules</h2>
            <p>
              Use every target letter exactly once in each row, each column and
              each bold 3×3 box. A repeated letter conflicts with the rules.
              Given letters are fixed; empty cells are yours to solve.
            </p>
            <h2>The extra rule: one hidden line</h2>
            <p>
              Exactly one row, read left to right, or one column, read top to
              bottom, spells the target in order. Other rows and columns contain
              the same letters in different orders. The hidden line is part of
              the puzzle’s logic—not a bonus unrelated to its solution.
            </p>
            <div className="lesson-example">
              <strong>Rule out a line</strong>
              <p>
                If ALGORITHM is the target, its first letter must be A. A row
                beginning with a fixed M cannot be the hidden row. An empty
                first cell, however, does not rule the row out. Check all nine
                positions.
              </p>
            </div>
            <h2>Choose your level</h2>
            <ul>
              <li>
                <strong>Easy:</strong> the target line is shown, giving you a
                guided start.
              </li>
              <li>
                <strong>Medium:</strong> identify the hidden line. A correct
                choice fills it.
              </li>
              <li>
                <strong>Hard:</strong> Expert Deduction confirms the correct
                line, but you place its letters yourself.
              </li>
              <li>
                <strong>Pro:</strong> solve without revealing hints or automatic
                line fills.
              </li>
            </ul>
            <h2>Your controls</h2>
            <p>
              Select a cell, then a letter. The number below a letter says how
              many placements remain. Notes add pencil candidates rather than a
              final entry. Erase clears your own entry; Undo reverses a recent
              action. A hint reveals the selected empty cell in Easy–Hard. Use
              the line controls to consider or identify the target row or
              column.
            </p>
            <p>
              The practice tutorial inside Classic walks through placing a
              letter and identifying a line. Settings contains credits and legal
              links. The technique reference is also available inside the game.
            </p>
            <h2>Leave and come back</h2>
            <p>
              Your current puzzle saves in this browser. Continue restores the
              board and notes. Starting a new free-play puzzle replaces that
              mode’s save after confirmation. Daily challenges use date-specific
              save slots. Private browsing, clearing storage, or switching
              devices can remove or separate progress.
            </p>
            <p>
              Web play is unlimited. Revealing hints are free during the launch
              beta; Pro remains unassisted. There are no web purchases.
            </p>
          </>
        ) : slug === "mega-guide" ? (
          <>
            <h1>Think bigger, one box at a time.</h1>
            <p>
              Mega uses a 25×25 board split into twenty-five 5×5 boxes. Each
              row, column and box contains A through Y exactly once. Z is not
              used. There is no hidden word or hidden-line rule.
            </p>
            <h2>Start where the information is</h2>
            <p>
              Look for a nearly full row or box. List the letters missing from
              it, then use crossing columns to rule candidates out. You do not
              have to survey all 625 cells at once.
            </p>
            <p>
              Mega is available on desktop and laptop screens at least 1,200
              pixels wide and 700 pixels tall.
            </p>
            <h2>A workspace for a large puzzle</h2>
            <ul>
              <li>
                <strong>Focus on a box:</strong> display one 5×5 box at a
                readable size. Use the box selector to move around the full
                board.
              </li>
              <li>
                <strong>Larger letters:</strong> increase the letter size while
                keeping the full board on one screen.
              </li>
              <li>
                <strong>High contrast:</strong> make letters and grid lines more
                distinct.
              </li>
              <li>
                <strong>Keyboard:</strong> arrow keys move, A–Y enters a letter,
                Backspace erases, and Space toggles notes.
              </li>
            </ul>
            <h2>Notes, hints and mistakes</h2>
            <p>
              Notes are manually entered candidates, not an automatic solution.
              A small dot marker on the full board indicates notes; focus mode
              or larger letters to read them. Duplicate letters in a shared row,
              column or box are marked as conflicts. A non-conflicting letter is
              not necessarily correct.
            </p>
            <p>
              Hints reveal an empty selected cell. Pro disables them. Undo
              restores a recent entry or notes. Undoing a revealed hint does not
              erase the fact that assistance was used.
            </p>
            <h2>Difficulty in the first edition</h2>
            <p>
              Easy starts with more clues; the higher tiers remove more. Every
              removal is accepted only when its value is forced by the clues
              remaining at that step. Restoring those forced values in reverse
              proves that the puzzle has one solution. These tiers are not yet
              rated by advanced human techniques.
            </p>
            <h2>The weekly challenge</h2>
            <p>
              A shared Medium board changes each Monday at 00:00 UTC. It has a
              save separate from free play. Opening another week replaces the
              weekly slot. Your browser stores completed-board counts; there is
              no account or public leaderboard.
            </p>
          </>
        ) : (
          <>
            <h1>From a pencil mark to a certain move.</h1>
            <p>
              A useful deduction tells you why a move must be true. Here is a
              small candidate example using the letters A–I. It is a unit
              illustration, not an entire playable Sudoku.
            </p>
            <h2>1. Write the missing letters</h2>
            <p>
              Suppose a row already contains D, E, F, G, H and I. Its three
              remaining cells must hold A, B and C.
            </p>
            <div
              className="note-pair"
              aria-label="Three unsolved cells: A B, A B, A B C"
            >
              <span>A B</span>
              <span>A B</span>
              <span>A B C</span>
            </div>
            <h2>2. Find the reservation</h2>
            <p>
              After checking columns and boxes, the first two cells each allow
              only A or B. Whichever one becomes A, the other becomes B. Those
              two letters are reserved for those two cells.
            </p>
            <h2>3. Use the consequence</h2>
            <p>
              The third cell cannot be A or B. Its remaining candidate is C, so
              C is a forced placement. You did not need to guess the order of
              the first two cells.
            </p>
            <h2>4. Check the condition</h2>
            <p>
              If either of the first two cells also allowed C, this naked-pair
              argument would fail. That is why complete, up-to-date candidates
              matter. A pair is a statement about all legal options, not just
              two letters you happened to pencil in.
            </p>
            <Link href="/learn/naked-pair">Read the naked-pair rule →</Link>
          </>
        )}
        <div className="button-row">
          <Link className="button primary" href="/alphadoku/classic">
            Try Classic ↗
          </Link>
          <Link className="button secondary" href="/alphadoku/mega">
            Try Mega ↗
          </Link>
        </div>
      </main>
    </WebShell>
  );
}

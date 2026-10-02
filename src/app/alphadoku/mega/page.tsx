import Link from "next/link";
import { WebShell, AlphaIdentity } from "../../_components/WebShell";
import MegaGate from "../../_game/MegaGate";
import { utcDay, weekStart } from "../../_lib/challenges";
export const metadata = {
  title: "Play Mega Alphadoku — 25×25 alphabet Sudoku",
  description:
    "A to Y, 25 rows, 25 columns and 5×5 boxes. Play free Mega Sudoku with notes, keyboard controls, hints and automatic saves.",
};
export default async function Page({
  searchParams,
}: {
  searchParams: Promise<{ week?: string }>;
}) {
  const { week } = await searchParams;
  const valid =
    week &&
    /^\d{4}-\d{2}-\d{2}$/.test(week) &&
    !Number.isNaN(Date.parse(week)) &&
    week >= weekStart("2026-10-02") &&
    week <= utcDay() &&
    weekStart(week) === week
      ? week
      : undefined;
  return (
    <WebShell>
      <main id="main" className="play-page mega-play-page">
        <div className="play-heading">
          <AlphaIdentity />
          <nav>
            <Link href="/alphadoku/classic">Play Classic ↗</Link>
            <Link href="/learn/mega-guide">Mega guide</Link>
          </nav>
        </div>
        <h1>
          Mega {valid ? `· Week of ${valid}` : "· The whole alphabet. Almost."}
        </h1>
        <p>
          Place A–Y once in every row, column and 5×5 box. No hidden line. Start
          with the full board, or focus on one box.
        </p>
        <MegaGate key={valid ?? "free"} week={valid} />
      </main>
    </WebShell>
  );
}

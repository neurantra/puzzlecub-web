import Link from "next/link";
import { WebShell } from "../_components/WebShell";
import { utcDay, weekStart, LAUNCH_DAY } from "../_lib/challenges";
export const dynamic = "force-dynamic";
export const metadata = {
  title: "Daily Classic & weekly Mega challenges — PuzzleCub",
};
export default function Page() {
  const today = utcDay(),
    week = weekStart(today);
  const days = Array.from({ length: 30 }, (_, i) =>
    utcDay(new Date(Date.parse(today) - i * 86400000)),
  ).filter((d) => d >= LAUNCH_DAY);
  return (
    <WebShell>
      <main id="main" className="web-section">
        <span className="tag">A LITTLE RITUAL</span>
        <h1 className="page-title">
          Make time for
          <br />a fresh perspective.
        </h1>
        <p className="intro">
          One Classic board each day. One Mega board each week. Everyone starts
          with the same puzzle. Days change at midnight UTC; weeks begin Monday.
          Play at your own pace.
        </p>
        <div className="challenge-links">
          <Link href={`/alphadoku/classic?day=${today}`}>
            <span className="tag">TODAY · {today}</span>
            <h2>Daily Classic</h2>
            <p>Medium · Nine letters, one hidden line.</p>
            <strong>Take today’s challenge ↗</strong>
          </Link>
          <Link href={`/alphadoku/mega?week=${week}`}>
            <span className="tag">WEEK OF {week}</span>
            <h2>Weekly Mega</h2>
            <p>Medium · A to Y. Room to think.</p>
            <strong>Start this week’s board ↗</strong>
          </Link>
        </div>
        <h2 className="section-title">The Classic archive</h2>
        <p>
          Revisit a challenge from the last 30 days. A challenge save is
          separate from free play; opening a different date starts that date’s
          board.
        </p>
        <div className="archive-links">
          {days.map((d) => (
            <Link key={d} href={`/alphadoku/classic?day=${d}`}>
              {d} <span>Play →</span>
            </Link>
          ))}
        </div>
      </main>
    </WebShell>
  );
}

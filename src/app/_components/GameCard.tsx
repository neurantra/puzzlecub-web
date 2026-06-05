import Link from "next/link";
import type { Game } from "../_lib/games";
import { QuestIcon } from "./QuestIcon";

export function GameCard({ game }: { game: Game }) {
  return (
    <Link
      href={`/games/${game.slug}`}
      className="group flex flex-col rounded-2xl border border-line bg-surface p-7 transition-all hover:-translate-y-0.5 hover:bg-surface-hi hover:shadow-[0_10px_28px_-14px_rgba(0,0,0,0.4)]"
      style={{
        borderTopColor: `var(${game.accentVar})`,
        borderTopWidth: 3,
      }}
    >
      <QuestIcon name={game.iconKey} size={52} />
      <h3 className="mt-5 text-[22px] font-bold tracking-tight text-foreground">
        {game.name}
      </h3>
      <p className="mt-2 text-[15px] font-medium text-foreground/85">
        {game.tagline}
      </p>
      <p className="mt-4 flex-1 text-[14px] leading-relaxed text-muted">
        {game.short}
      </p>
      <p
        className="mt-6 inline-flex items-center text-[13px] font-semibold transition-transform group-hover:translate-x-0.5"
        style={{ color: `var(${game.accentVar})` }}
      >
        Learn more →
      </p>
    </Link>
  );
}

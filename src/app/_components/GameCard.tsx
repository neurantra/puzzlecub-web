import Image from "next/image";
import Link from "next/link";
import type { Game } from "../_lib/games";
export function GameCard({ game }: { game: Game }) {
  return (
    <Link
      href={`/games/${game.slug}`}
      className="group overflow-hidden rounded-3xl border border-line bg-surface transition-transform hover:-translate-y-1"
    >
      <div className="flex justify-center bg-[#E6EEDB] px-8 pt-8">
        <Image
          src={game.screenshot}
          alt={game.screenshotAlt}
          width={800}
          height={1738}
          sizes="(min-width: 1024px) 230px, 260px"
          className="h-[310px] w-auto rounded-t-2xl object-contain object-top"
        />
      </div>
      <div className="p-7">
        <h3 className="text-2xl font-bold tracking-tight">{game.name}</h3>
        <p className="mt-3 text-sm leading-relaxed text-muted">{game.short}</p>
        <p className="mt-5 text-sm font-bold text-accent">Explore the game →</p>
      </div>
    </Link>
  );
}

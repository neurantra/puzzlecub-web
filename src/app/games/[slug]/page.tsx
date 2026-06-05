import type { Metadata } from "next";
import Image from "next/image";
import { notFound } from "next/navigation";
import { ChaturangStrip } from "../../_components/ChaturangStrip";
import { GameCard } from "../../_components/GameCard";
import { QuestIcon } from "../../_components/QuestIcon";
import { SiteFooter } from "../../_components/SiteFooter";
import { SiteHeader } from "../../_components/SiteHeader";
import {
  APP_STORE_URL,
  GAMES,
  PLAY_STORE_URL,
  getGame,
} from "../../_lib/games";

export function generateStaticParams() {
  return GAMES.map(g => ({ slug: g.slug }));
}

export async function generateMetadata(
  { params }: PageProps<"/games/[slug]">,
): Promise<Metadata> {
  const { slug } = await params;
  const game = getGame(slug);
  if (!game) return {};
  return {
    title: `${game.name} — Puzzlecub`,
    description: `${game.tagline} ${game.short}`,
  };
}

export default async function GamePage(
  { params }: PageProps<"/games/[slug]">,
) {
  const { slug } = await params;
  const game = getGame(slug);
  if (!game) notFound();

  return (
    <div className="flex flex-col flex-1">
      <SiteHeader variant="subpage" />

      {/* ── Hero ── */}
      <section className="border-b border-line">
        <div className="mx-auto max-w-6xl px-6 py-16 sm:px-10 sm:py-20">
          <div className="flex flex-col items-start gap-6">
            <QuestIcon name={game.iconKey} size={84} />
            <p
              className="text-[11px] font-semibold uppercase tracking-[0.22em]"
              style={{ color: `var(${game.accentVar})` }}
            >
              {game.name}
            </p>
            <h1 className="max-w-3xl text-[40px] font-extrabold leading-[1.05] tracking-[-0.02em] text-foreground sm:text-[60px]">
              {game.tagline}
            </h1>
          </div>
        </div>
      </section>

      {/* ── Detail ── */}
      <section className="border-b border-line">
        <div className="mx-auto grid max-w-6xl gap-12 px-6 py-20 sm:px-10 sm:py-24 lg:grid-cols-[1.3fr_1fr] lg:items-center">
          <div>
            <p className="text-base leading-relaxed text-muted sm:text-[17px]">
              {game.body}
            </p>
            <p className="mt-8 text-[11px] font-semibold uppercase tracking-[0.18em] text-muted">
              {game.skills}
            </p>
          </div>
          {game.screenshot ? (
            <div className="relative mx-auto aspect-[9/19.5] w-full max-w-[320px]">
              <Image
                src={game.screenshot}
                alt={game.screenshotAlt ?? ""}
                fill
                className="object-contain"
                sizes="(min-width: 1024px) 320px, 80vw"
              />
            </div>
          ) : (
            <div className="mx-auto flex aspect-[9/19.5] w-full max-w-[320px] items-center justify-center">
              <QuestIcon name={game.iconKey} size={180} />
            </div>
          )}
        </div>
      </section>

      {/* ── Get it ── */}
      <section className="border-b border-line">
        <div className="mx-auto max-w-6xl px-6 py-20 sm:px-10 sm:py-24">
          <p className="mb-6 text-[11px] font-semibold uppercase tracking-[0.22em] text-muted">
            Get Puzzlecub
          </p>
          <h2 className="max-w-2xl text-3xl font-bold leading-tight tracking-tight text-foreground sm:text-4xl">
            {game.name} is one of six games inside Puzzlecub.
          </h2>
          <p className="mt-6 max-w-xl text-base leading-relaxed text-muted">
            Free, ad-supported, no account required. Live on iOS and Android.
          </p>
          <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:items-center">
            <a
              href={APP_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex h-12 items-center justify-center rounded-full bg-foreground px-7 text-sm font-semibold text-background transition-opacity hover:opacity-90"
            >
              Download on the App Store
            </a>
            <a
              href={PLAY_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex h-12 items-center justify-center rounded-full border border-foreground/30 bg-transparent px-7 text-sm font-semibold text-foreground transition-colors hover:bg-foreground hover:text-background"
            >
              Get it on Google Play
            </a>
          </div>
        </div>
      </section>

      {/* ── Did you see? ── */}
      <section className="border-b border-line">
        <div className="mx-auto max-w-6xl px-6 py-20 sm:px-10 sm:py-24">
          <p className="mb-10 text-[11px] font-semibold uppercase tracking-[0.22em] text-muted">
            Did you see?
          </p>
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {GAMES.filter(g => g.slug !== game.slug).map(g => (
              <GameCard key={g.slug} game={g} />
            ))}
          </div>
        </div>
      </section>

      <ChaturangStrip />

      <SiteFooter />
    </div>
  );
}

import Image from "next/image";
import { ChaturangStrip } from "./_components/ChaturangStrip";
import { GameCard } from "./_components/GameCard";
import { SiteFooter } from "./_components/SiteFooter";
import { SiteHeader } from "./_components/SiteHeader";
import { APP_STORE_URL, GAMES, PLAY_STORE_URL } from "./_lib/games";

export default function Home() {
  return (
    <div className="flex flex-col flex-1">
      <SiteHeader variant="home" />

      {/* ── Hero ── */}
      <section className="border-b border-line">
        <div className="mx-auto max-w-3xl px-6 py-20 text-center sm:px-10 sm:py-28">
          <div className="mb-7 flex justify-center">
            <Image
              src="/puzzlecub-logo.png"
              alt="Puzzlecub"
              width={160}
              height={160}
              priority
              className="h-[160px] w-[160px]"
            />
          </div>
          <div className="mb-7 flex justify-center">
            <span className="inline-flex items-center whitespace-nowrap rounded-full bg-surface px-3 py-1 text-[10px] font-semibold uppercase tracking-wider text-muted">
              Live on iOS &amp; Android
            </span>
          </div>
          <h1 className="text-[44px] font-extrabold leading-[1.04] tracking-[-0.02em] text-foreground sm:text-[64px]">
            Seven quests.<br />One Puzzlecub.
          </h1>
          <p className="mx-auto mt-7 max-w-xl text-lg leading-relaxed text-muted">
            One app, seven AI-driven games — Math, Word, Sand, Alpha, Maze,
            Geo, and Stack. Bound together by a shared wallet, a daily streak,
            a Daily Challenge, and an AI that adapts to how you play.
          </p>
          <div className="mt-10 flex flex-col items-center justify-center gap-3 sm:flex-row">
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

      {/* ── What is Puzzlecub? ── */}
      <section className="border-b border-line">
        <div className="mx-auto max-w-6xl px-6 py-20 sm:px-10 sm:py-24">
          <p className="mb-10 text-[11px] font-semibold uppercase tracking-[0.22em] text-muted">
            What is Puzzlecub?
          </p>
          <div className="grid gap-12 lg:grid-cols-2">
            <div>
              <h2 className="text-[28px] font-bold leading-tight tracking-tight text-foreground sm:text-[34px]">
                One app. Seven different ways to play.
              </h2>
              <p className="mt-6 text-base leading-relaxed text-muted">
                Puzzlecub is one app with seven games tucked inside — each its
                own quest, each with its own rules. A shared wallet spans them
                all. A daily streak follows you across them. A Daily Challenge
                picks one each day to surprise you.
              </p>
              <p className="mt-4 text-base leading-relaxed text-muted">
                The AI is woven through gameplay, not bolted on. It tunes
                difficulty as you play. It races you in vs-AI modes. It picks
                the next puzzle based on what you&rsquo;ve already seen.
              </p>
            </div>
            <div>
              <h2 className="text-[28px] font-bold leading-tight tracking-tight text-foreground sm:text-[34px]">
                Made for everyone. Safe for kids.
              </h2>
              <p className="mt-6 text-base leading-relaxed text-muted">
                On first launch Puzzlecub asks one thing — your year of birth —
                and uses that, locally, to decide what to show you. Under 13:
                ads are non-personalized through Google&rsquo;s kid-safe
                certified network, and outbound links are protected by a
                parental gate.
              </p>
              <p className="mt-4 text-base leading-relaxed text-muted">
                Older players: friction free. Either way, no account is
                required, no progress leaves your device, and no personal
                information is ever collected.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ── The seven quests ── */}
      <section id="games" className="scroll-mt-24 border-b border-line">
        <div className="mx-auto max-w-6xl px-6 py-20 sm:px-10 sm:py-24">
          <p className="mb-10 text-[11px] font-semibold uppercase tracking-[0.22em] text-muted">
            The seven quests
          </p>
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {GAMES.map(g => (
              <GameCard key={g.slug} game={g} />
            ))}
          </div>
        </div>
      </section>

      {/* ── Get it ── */}
      <section className="border-b border-line">
        <div className="mx-auto max-w-6xl px-6 py-20 sm:px-10 sm:py-24">
          <p className="mb-6 text-[11px] font-semibold uppercase tracking-[0.22em] text-muted">
            Get Puzzlecub
          </p>
          <h2 className="max-w-2xl text-3xl font-bold leading-tight tracking-tight text-foreground sm:text-4xl">
            Seven games, one cub. Free, ad-supported, no account required.
          </h2>
          <p className="mt-6 max-w-xl text-base leading-relaxed text-muted">
            Puzzlecub is live now on iOS and Android. Tap a store below to
            download.
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

      <ChaturangStrip />

      <SiteFooter />
    </div>
  );
}

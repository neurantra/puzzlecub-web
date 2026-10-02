import type { Metadata } from "next";
import Image from "next/image";
import { ChaturangStrip } from "../_components/ChaturangStrip";
import { SiteFooter } from "../_components/SiteFooter";
import { SiteHeader } from "../_components/SiteHeader";
import { APP_STORE_URL, GAMES, PLAY_STORE_URL } from "../_lib/games";

export const metadata: Metadata = {
  title:
    "Download Puzzlecub — Four number and word games, free on iOS & Android",
  description:
    "Get Puzzlecub free on the App Store and Google Play. Tap the Answer, Answer It, Build the Sum, and Find the Word, with daily challenges and a cross-app Coin Vault.",
};

/** Official store badges — used as the primary download CTA. */
function StoreBadges({ className = "" }: { className?: string }) {
  return (
    <div
      className={`flex flex-wrap items-center justify-center gap-4 ${className}`}
    >
      <a
        href={APP_STORE_URL}
        target="_blank"
        rel="noopener noreferrer"
        className="transition-opacity hover:opacity-85"
        aria-label="Download on the App Store"
      >
        <Image
          src="/puzzlecub/badge-app-store.png"
          alt="Download on the App Store"
          width={168}
          height={56}
          className="h-14 w-auto"
        />
      </a>
      <a
        href={PLAY_STORE_URL}
        target="_blank"
        rel="noopener noreferrer"
        className="transition-opacity hover:opacity-85"
        aria-label="Get it on Google Play"
      >
        <Image
          src="/puzzlecub/badge-google-play.png"
          alt="Get it on Google Play"
          width={145}
          height={56}
          className="h-14 w-auto"
        />
      </a>
    </div>
  );
}

const HIGHLIGHTS = [
  {
    title: "Four games in one",
    body: "Tap the Answer, Answer It, Build the Sum, and Find the Word — quick-thinking number and word challenges.",
  },
  {
    title: "Keep your streak",
    body: "Daily challenges, earned coins, personal bests, and harder trails give you a reason for another round.",
  },
  {
    title: "Lively rounds",
    body: "Catch falling answers and race the clock. Quick feedback and automatic progression keep the action moving.",
  },
  {
    title: "Cross-app Coin Vault",
    body: "Link Puzzlecub and Chaturang to transfer earned coins when the Vault is available. Internet access and an eligible profile are required.",
  },
  {
    title: "Choose your challenge",
    body: "Adjust difficulty and round settings, or take an untimed scenic round in Tap the Answer.",
  },
  {
    title: "More to discover",
    body: "Find separate downloads for Fill the Jar, Mapopia, Maze Words, and Slide & Sort on our home page.",
  },
];

export default function DownloadPage() {
  return (
    <div className="flex flex-col flex-1">
      <SiteHeader variant="subpage" />

      {/* ── Hero ── */}
      <section className="border-b border-line">
        <div className="mx-auto max-w-3xl px-6 py-20 text-center sm:px-10 sm:py-28">
          <div className="mb-7 flex justify-center">
            <Image
              src="/puzzlecub/icon.webp"
              alt="Puzzlecub"
              width={140}
              height={140}
              priority
              className="h-[140px] w-[140px]"
            />
          </div>
          <div className="mb-7 flex justify-center">
            <span className="inline-flex items-center whitespace-nowrap rounded-full bg-surface px-3 py-1 text-[10px] font-semibold uppercase tracking-wider text-muted">
              Free · Live on iOS &amp; Android
            </span>
          </div>
          <h1 className="text-[44px] font-extrabold leading-[1.04] tracking-[-0.02em] text-foreground sm:text-[60px]">
            Get Puzzlecub
          </h1>
          <p className="mx-auto mt-6 max-w-xl text-lg leading-relaxed text-muted">
            Four number and word games in one app. Free, ad-supported, no
            account required. Tap a store to download and start playing.
          </p>
          <StoreBadges className="mt-10" />
        </div>
      </section>

      {/* ── What you get ── */}
      <section className="border-b border-line">
        <div className="mx-auto max-w-6xl px-6 py-20 sm:px-10 sm:py-24">
          <p className="mb-10 text-[11px] font-semibold uppercase tracking-[0.22em] text-muted">
            What you get
          </p>
          <div className="grid gap-x-12 gap-y-10 sm:grid-cols-2 lg:grid-cols-3">
            {HIGHLIGHTS.map((h) => (
              <div key={h.title}>
                <h2 className="text-lg font-bold tracking-tight text-foreground">
                  {h.title}
                </h2>
                <p className="mt-3 text-base leading-relaxed text-muted">
                  {h.body}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Screenshots ── */}
      <section className="border-b border-line">
        <div className="mx-auto max-w-6xl px-6 py-20 sm:px-10 sm:py-24">
          <p className="mb-10 text-[11px] font-semibold uppercase tracking-[0.22em] text-muted">
            A look inside
          </p>
          <div className="flex flex-wrap justify-center gap-x-6 gap-y-10">
            {GAMES.map((g) => {
              const shot = g.screenshot;
              if (!shot) return null;
              return (
                <figure key={g.slug} className="w-[200px]">
                  <div
                    className="overflow-hidden rounded-[24px] border"
                    style={{ borderColor: `var(${g.accentVar})` }}
                  >
                    <Image
                      src={shot}
                      alt={`${g.name} — ${g.tagline}`}
                      width={200}
                      height={435}
                      className="block h-auto w-full"
                    />
                  </div>
                  <figcaption className="mt-4 text-center">
                    <span
                      className="text-sm font-bold"
                      style={{ color: `var(${g.accentVar})` }}
                    >
                      {g.name}
                    </span>
                    <span className="mt-0.5 block text-xs text-muted">
                      {g.tagline}
                    </span>
                  </figcaption>
                </figure>
              );
            })}
          </div>
        </div>
      </section>

      {/* ── Get it ── */}
      <section className="border-b border-line">
        <div className="mx-auto max-w-6xl px-6 py-20 text-center sm:px-10 sm:py-24">
          <h2 className="mx-auto max-w-2xl text-3xl font-bold leading-tight tracking-tight text-foreground sm:text-4xl">
            Four games. One more round.
          </h2>
          <p className="mx-auto mt-6 max-w-xl text-base leading-relaxed text-muted">
            Puzzlecub is live now on iOS and Android.
          </p>
          <StoreBadges className="mt-8" />
        </div>
      </section>

      <ChaturangStrip />

      <SiteFooter />
    </div>
  );
}

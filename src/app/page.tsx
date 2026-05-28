import Image from "next/image";

const APP_STORE = "https://apps.apple.com/us/app/questiverse/id6768766852";
const PLAY_STORE = "https://play.google.com/store/apps/details?id=com.sumquest.app";

export default function Home() {
  return (
    <main className="flex flex-1 flex-col items-center justify-center px-6 py-24 text-center">
      <Image
        src="/puzzlecub-logo.png"
        alt="Puzzlecub"
        width={140}
        height={140}
        priority
        className="rounded-3xl shadow-sm"
      />
      <h1 className="mt-8 text-4xl font-semibold tracking-tight sm:text-5xl">
        Puzzlecub
      </h1>
      <p className="mt-5 max-w-md text-sm leading-relaxed text-foreground/60 sm:text-base">
        Six AI-driven games — Math, Word, Sand, Alpha, Maze, and Geo —
        bound together by one playful cub. The site is being built.
      </p>
      <p className="mt-8 text-[10px] font-semibold uppercase tracking-[0.22em] text-foreground/40">
        Coming soon
      </p>
      <div className="mt-10 flex flex-col gap-3 sm:flex-row">
        <a
          href={APP_STORE}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex h-11 items-center justify-center rounded-full bg-foreground px-6 text-sm font-semibold text-background transition-opacity hover:opacity-90"
        >
          Download on the App Store
        </a>
        <a
          href={PLAY_STORE}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex h-11 items-center justify-center rounded-full border border-foreground/15 px-6 text-sm font-semibold text-foreground transition-colors hover:border-foreground/40"
        >
          Get it on Google Play
        </a>
      </div>
      <p className="mt-16 text-xs text-foreground/40">
        Made by{" "}
        <a
          href="https://neurantra.com"
          target="_blank"
          rel="noopener noreferrer"
          className="underline underline-offset-4 hover:text-foreground/60"
        >
          Neurantra
        </a>
      </p>
    </main>
  );
}

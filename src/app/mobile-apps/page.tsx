import Image from "next/image";
import { ChaturangStrip } from "../_components/ChaturangStrip";
import { GameCard } from "../_components/GameCard";
import { SiteFooter } from "../_components/SiteFooter";
import { SiteHeader } from "../_components/SiteHeader";
import { StoreLinks } from "../_components/StoreLinks";
import { StandaloneApps } from "../_components/StandaloneApps";
import { GAMES } from "../_lib/games";
export const metadata = { title: "PuzzleCub apps — Independent games by Neurantra", alternates: {canonical: "https://puzzlecub.app/"} };
export default function Home() {
  return (
    <div className="flex flex-1 flex-col">
      <SiteHeader variant="home" />
      <main>
        <section className="border-b border-line">
          <div className="section-wrap grid items-center gap-12 lg:grid-cols-[1.2fr_1fr]">
            <div>
              <Image
                src="/puzzlecub/icon.webp"
                alt="Puzzlecub icon"
                width={100}
                height={100}
                priority
                className="mb-8 rounded-3xl"
              />
              <p className="eyebrow">A little thought. A bright discovery.</p>
              <h1 className="text-5xl font-extrabold leading-[1.05] tracking-tight sm:text-7xl">
                Four games.
                <br />
                One more
                <br />
                <span className="text-accent">“got it!”</span>
              </h1>
              <p className="mt-7 max-w-xl text-lg leading-relaxed text-muted">
                Catch falling answers, solve mental-math challenges, build sums,
                and uncover hidden words. Puzzlecub brings four quick-thinking
                games together with a fresh look and plenty of reasons for one
                more round.
              </p>
              <div className="mt-8">
                <StoreLinks />
              </div>
              <p className="mt-4 text-sm text-muted">
                For iOS and Android · Free, ad-supported play
              </p>
            </div>
            <div className="grid grid-cols-2 items-center gap-4 rounded-[40px] bg-[#E6EEDB] p-5 sm:p-7">
              <Image
                src="/puzzlecub/math.webp"
                alt="Catch falling numbers in Tap the Answer"
                width={800}
                height={1738}
                priority
                sizes="(min-width: 1024px) 220px, 40vw"
                className="h-auto w-full rounded-2xl shadow-xl"
              />
              <Image
                src="/puzzlecub/word.webp"
                alt="Solve clues in Find the Word"
                width={800}
                height={1738}
                priority
                sizes="(min-width: 1024px) 220px, 40vw"
                className="mt-12 h-auto w-full rounded-2xl shadow-xl"
              />
            </div>
          </div>
        </section>
        <section id="games" className="scroll-mt-24 border-b border-line">
          <div className="section-wrap">
            <p className="eyebrow">Inside Puzzlecub</p>
            <h2 className="section-title">
              Four ways to keep your mind moving.
            </h2>
            <p className="mt-5 max-w-2xl text-lg leading-relaxed text-muted">
              Quick feedback, lively rounds, and a challenge you can make your
              own. Pause when you need a breather; come back ready for the next
              puzzle.
            </p>
            <div className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
              {GAMES.map((game) => (
                <GameCard key={game.slug} game={game} />
              ))}
            </div>
          </div>
        </section>
        <section className="border-b border-line">
          <div className="section-wrap grid gap-10 md:grid-cols-3">
            <div>
              <p className="eyebrow">Keep exploring</p>
              <h2 className="text-2xl font-bold">A fresh reason to return.</h2>
              <p className="mt-4 leading-relaxed text-muted">
                Take on daily challenges, build streaks, earn coins, unlock
                tougher trails, and chase your personal bests.
              </p>
            </div>
            <div>
              <p className="eyebrow">Play your way</p>
              <h2 className="text-2xl font-bold">Find your next challenge.</h2>
              <p className="mt-4 leading-relaxed text-muted">
                Choose difficulty levels and round settings. Warm up with
                numbers, race the clock, or take an untimed scenic round in Tap
                the Answer.
              </p>
            </div>
            <div>
              <p className="eyebrow">Cross-app Coin Vault</p>
              <h2 className="text-2xl font-bold">Let your coins travel.</h2>
              <p className="mt-4 leading-relaxed text-muted">
                Link Puzzlecub and Chaturang with a one-time code, bank earned
                coins into the shared Coin Vault, then collect them in the
                linked game.
              </p>
              <p className="mt-3 text-xs leading-relaxed text-muted">
                Transfers need an internet connection and an eligible profile,
                and are available when the shared Vault is enabled. Game
                progress and purchases are separate.
              </p>
            </div>
          </div>
        </section>
        <StandaloneApps />
        <ChaturangStrip />
      </main>
      <SiteFooter />
    </div>
  );
}

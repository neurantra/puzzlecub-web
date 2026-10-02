import Image from "next/image";
import {
  CHATURANG_URL,
  CHATURANG_APP_STORE_URL,
  CHATURANG_PLAY_STORE_URL,
} from "../_lib/games";
import { StoreLinks } from "./StoreLinks";
export function ChaturangStrip() {
  return (
    <section id="chaturang" className="scroll-mt-24">
      <div className="section-wrap">
        <div className="grid items-center gap-10 overflow-hidden rounded-3xl border border-line bg-surface p-7 sm:p-10 lg:grid-cols-[1fr_280px]">
          <div>
            <p className="eyebrow">A different kind of strategy</p>
            <Image
              src="/chaturang/icon.webp"
              alt="Chaturang icon"
              width={80}
              height={80}
              className="mb-6 rounded-2xl"
            />
            <h2 className="section-title">
              Chaturang.
              <br />
              Your move, Your Majesty.
            </h2>
            <p className="mt-6 max-w-xl text-base leading-relaxed text-muted">
              Discover the Indian ancestor of chess in a palace court, with
              sculpted pieces and a richly detailed board. Challenge three AI
              levels or invite a friend to an online match. Learn the army, plan
              your moves, and make the court your own with cosmetic finishes.
            </p>
            <p className="mt-4 text-sm leading-relaxed text-muted">
              Try one free match, shared across AI and online play. A one-time
              full-game purchase unlocks unlimited matches.
            </p>
            <div className="mt-7">
              <StoreLinks
                name="Chaturang"
                appStoreUrl={CHATURANG_APP_STORE_URL}
                playStoreUrl={CHATURANG_PLAY_STORE_URL}
              />
            </div>
            <a
              href={CHATURANG_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="mt-5 inline-block text-sm font-bold text-accent"
            >
              Explore Chaturang ↗
            </a>
          </div>
          <Image
            src="/chaturang/board.webp"
            alt="Chaturang’s palace-court board with sculpted pieces"
            width={800}
            height={1738}
            sizes="(min-width: 1024px) 280px, 70vw"
            className="mx-auto h-auto max-h-[580px] w-auto max-w-full rounded-2xl"
          />
        </div>
      </div>
    </section>
  );
}

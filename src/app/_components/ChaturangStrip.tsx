import Image from "next/image";
import { CHATURANG_URL } from "../_lib/games";

export function ChaturangStrip() {
  return (
    <section>
      <div className="mx-auto max-w-6xl px-6 py-20 sm:px-10 sm:py-24">
        <p className="mb-8 text-[11px] font-semibold uppercase tracking-[0.22em] text-muted">
          Also from Neurantra
        </p>
        <a
          href={CHATURANG_URL}
          target="_blank"
          rel="noopener noreferrer"
          className="group flex flex-col gap-6 rounded-2xl border border-line bg-surface p-7 transition-all hover:-translate-y-0.5 hover:border-chaturang/60 hover:bg-surface-hi sm:flex-row sm:items-center sm:gap-8 sm:p-9"
          style={{ borderLeftColor: "var(--chaturang)", borderLeftWidth: 3 }}
        >
          <div className="flex h-20 w-20 shrink-0 items-center justify-center overflow-hidden rounded-2xl bg-[#3E2A1B] sm:h-24 sm:w-24">
            <Image
              src="/chaturang/chaturang-logo.png"
              alt="Chaturang"
              width={96}
              height={96}
              className="h-full w-full object-contain"
            />
          </div>
          <div className="flex-1">
            <p
              className="text-[11px] font-semibold uppercase tracking-[0.18em]"
              style={{ color: "var(--chaturang)" }}
            >
              Chaturang
            </p>
            <h3 className="mt-2 text-[22px] font-bold tracking-tight text-foreground sm:text-[26px]">
              The 8th-century ancestor of chess, reborn with a self-play-tuned AI.
            </h3>
            <p className="mt-3 text-[14px] leading-relaxed text-muted sm:text-[15px]">
              From the same team behind Puzzlecub. Three earned difficulty tiers,
              perfect King-and-Rook endgames from a built-in tablebase, and a
              Mughal-themed board. Live on iOS and Android.
            </p>
          </div>
          <p
            className="inline-flex shrink-0 items-center text-[13px] font-semibold transition-transform group-hover:translate-x-0.5"
            style={{ color: "var(--chaturang)" }}
          >
            Visit Chaturang →
          </p>
        </a>
      </div>
    </section>
  );
}

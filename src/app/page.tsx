import type { Metadata } from "next";
import Link from "next/link";
import { WebShell } from "./_components/WebShell";
import GameHub from "./_components/GameHub";
export const metadata: Metadata = {
  alternates: { canonical: "https://puzzlecub.com/" },
};
export default function Home() {
  return (
    <WebShell>
      <main id="main">
        <GameHub />
        <section className="app-banner">
          <div>
            <span className="tag">TAKE A LITTLE PLAY WITH YOU</span>
            <h2>Your favorites, on the go.</h2>
            <p>Discover the mobile editions of our independent games.</p>
          </div>
          <Link className="button secondary" href="/mobile-apps">
            Explore our apps ↗
          </Link>
        </section>
      </main>
    </WebShell>
  );
}

"use client";
import { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import PandaMascot from "./PandaMascot";
import { webGames, gamePreferenceKey, type WebGame } from "../_lib/web-games";

export default function GameHub() {
  const [selected, setSelected] = useState<WebGame>(webGames[0]);
  useEffect(() => {
    try {
      const saved = webGames.find(
        (game) => game.slug === localStorage.getItem(gamePreferenceKey),
      );
      if (saved) queueMicrotask(() => setSelected(saved));
    } catch {}
  }, []);
  function choose(game: WebGame) {
    setSelected(game);
    try {
      localStorage.setItem(gamePreferenceKey, game.slug);
    } catch {}
  }
  return (
    <section className="games-welcome game-hub" id="games">
      <div className="cub-welcome">
        <PandaMascot hero />
        <div className="cub-welcome-copy">
          <span className="tag">SIX WAYS TO FOLLOW YOUR CURIOSITY</span>
          <h1>
            Make time for <em>play.</em>
          </h1>
          <p>
            A quick puzzle or a longer adventure. What are you in the mood for?
          </p>
        </div>
      </div>
      <div className="game-picker" aria-label="Choose your game">
        {webGames.map((game) => (
          <button
            key={game.slug}
            aria-pressed={selected.slug === game.slug}
            onClick={() => choose(game)}
            aria-controls="featured-game"
          >
            <Image src={game.icon} alt="" width={64} height={64} />
            <strong>{game.name}</strong>
            <span>{game.category}</span>
          </button>
        ))}
      </div>
      <article
        className="featured-game"
        id="featured-game"
        style={{ "--game-color": selected.color } as React.CSSProperties}
      >
        <div className="featured-copy" aria-live="polite">
          <span className="tag">{selected.category} · FREE TO PLAY</span>
          <h2>{selected.name}</h2>
          <h3>{selected.tagline}</h3>
          <p>{selected.description}</p>
          <Link className="button primary" href={`/${selected.slug}`}>
            Play {selected.name} ↗
          </Link>
          <small>{selected.details}</small>
        </div>
        <div
          className={`featured-art ${selected.slug === "chaturang" ? "featured-court" : ""}`}
        >
          {selected.art ? (
            <Image
              src={selected.art}
              alt={`${selected.name} artwork`}
              fill
              sizes="(max-width: 700px) 90vw, 50vw"
              priority
            />
          ) : (
            <div className="collection-letter-grid" aria-hidden="true">
              {"ALGORITHM".split("").map((letter, i) => (
                <span className={i > 2 && i < 6 ? "lit" : ""} key={i}>
                  {letter}
                </span>
              ))}
            </div>
          )}
        </div>
      </article>
      <p className="games-note">
        Free to play · No account needed · No downloads
      </p>
      <nav className="game-direct-links" aria-label="All game pages">
        {webGames.map((game) => (
          <Link key={game.slug} href={`/${game.slug}`}>
            {game.name} ↗
          </Link>
        ))}
      </nav>
    </section>
  );
}

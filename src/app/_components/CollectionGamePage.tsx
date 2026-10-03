import Link from "next/link";
import { WebShell } from "./WebShell";
import { AdPlacement } from "./Advertising";
import { webGames } from "../_lib/web-games";

const instructions: Record<string, string[]> = {
  mazewords: [
    "Choose a difficulty and a timed or relaxed trail. Trace adjacent letters through open corridors; walls block your route. Lift your finger to submit a word, or switch to tap controls in the game settings.",
    "Find the common words to clear the maze. Bonus words earn extra points; hints use coins earned through play. Daily mazes give you a fresh reason to return. Your scores, coins, and preferences stay in this browser.",
  ],
  "slide-and-sort": [
    "Choose letters or numbers, then play solo or against Pip, the AI. Slide a tile along its row or column into the empty space to restore the right order. The help button shows the target arrangement.",
    "An optional timer and move limit add a little challenge. Sound, music, and reduced motion are in settings. Local wins and preferences are saved; leaving an unfinished round starts a fresh puzzle next time.",
  ],
  mapopia: [
    "Choose one of 18 maps and a play mode. Select a piece from the tray and place it where it belongs. Names, capitals, and hints help you discover the world as the map comes together.",
    "All maps are free on the web. Play relaxed or timed, try a daily expedition, and return to a saved expedition in the same browser. No purchases or account are needed.",
  ],
  fillthejar: [
    "Choose a pile, rotate a piece if needed, and drop it into the jar. Pieces settle into place. Tap an uncovered piece to lift it out, or use Undo to try a different fit. Fill the jar without gaps to move on.",
    "All 100 campaign levels are free. Solve jars to earn coins for hints, picture themes, and other in-game extras. There are no cash purchases. Progress, earned coins, and settings stay in this browser.",
  ],
};
export default function CollectionGamePage({ slug }: { slug: string }) {
  const game = webGames.find((g) => g.slug === slug)!;
  return (
    <WebShell>
      <main
        id="main"
        className="play-page chaturang-play-page collection-play-page"
      >
        <div className="play-heading">
          <Link href="/#games">← All games</Link>
          <nav>
            <Link href="#how-to-play">How to play</Link>
            <Link href="/privacy">Privacy</Link>
          </nav>
        </div>
        <h1>
          {game.name} <span>· {game.tagline}</span>
        </h1>
        <p>{game.category}. Free to play, right here.</p>
        <iframe
          title={`Playable ${game.name}`}
          className="chaturang-frame collection-frame"
          src={`/${slug}-game/index.html`}
          allow="fullscreen; autoplay"
        />
        <section className="play-explainer" id="how-to-play">
          <span className="tag">{game.category}</span>
          <h2>{game.tagline}</h2>
          {instructions[slug].map((p) => (
            <p key={p}>{p}</p>
          ))}
          <Link href="/#games">Find your next game →</Link>
        </section>
        <AdPlacement gameplay />
      </main>
    </WebShell>
  );
}

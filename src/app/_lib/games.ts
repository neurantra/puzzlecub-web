export type GameSlug =
  | "math"
  | "word"
  | "sand"
  | "alpha"
  | "maze"
  | "geo"
  | "stack";
export type IconKey =
  | "math"
  | "word"
  | "tide"
  | "alpha"
  | "geo"
  | "maze"
  | "stack";

export interface Game {
  slug: GameSlug;
  iconKey: IconKey;
  name: string;
  tagline: string;
  short: string;
  body: string;
  skills: string;
  screenshot: string | null;
  screenshotAlt?: string;
  accentVar: string;
}

export const APP_STORE_URL =
  "https://apps.apple.com/us/app/puzzlecub/id6768766852";
export const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.sumquest.app";

export const CHATURANG_URL = "https://neurantra.com/chaturang";

export const GAMES: Game[] = [
  {
    slug: "math",
    iconKey: "math",
    name: "Math Quest",
    tagline: "Find the answer, stop the drop.",
    short:
      "Quick-fire arithmetic, rendered as a quest. Streaks unlock the next scene; misses loosen the timer.",
    body:
      "Quick-fire arithmetic, rendered as a quest. Pick an operation, pick a difficulty, race the clock. Each correct answer unlocks the next scene of the quest and earns coins toward your wallet. The AI behind the scenes tunes pacing as you play: clean streaks accelerate, slips loosen the timer.",
    skills: "Addition · subtraction · multiplication · division · mixed mode",
    screenshot: "/puzzlecub/puzzlecub-math.png",
    screenshotAlt: "Math Quest gameplay — 11 + 18, Halloween scene",
    accentVar: "--game-math",
  },
  {
    slug: "word",
    iconKey: "word",
    name: "Word Quest",
    tagline: "Find the word, save the cart.",
    short:
      "A definition, an A-Z keyboard, a hidden word. Pick letters one at a time; each one tells you something.",
    body:
      "Each round gives you a definition. The keyboard runs A through Z; the word stays hidden. You pick letters one by one — each one tells you something. Hints peel back a single letter; reveal jumps to the answer. Word Quest grows your vocabulary without ever feeling like flashcards.",
    skills: "Vocabulary · spelling · pattern recognition",
    screenshot: "/puzzlecub/puzzlecub-word.png",
    screenshotAlt:
      "Word Quest gameplay — definition-driven word puzzle with A-Z keyboard",
    accentVar: "--game-word",
  },
  {
    slug: "sand",
    iconKey: "tide",
    name: "Sand Quest",
    tagline: "Stop the ball, save the castle.",
    short:
      "Math against a tide line. Right answers hold back the wave; wrong ones crumble a tower. Trivia in the margins.",
    body:
      "Math problems set against a tide line and a sandcastle you have to defend. Every right answer holds back the wave; every wrong one crumbles a tower. Each round serves up a piece of trivia alongside the problem — a fact about prime numbers, a stat about how far waves travel. Slower than Math Quest; the satisfaction is in the rhythm.",
    skills: "Mental math · numeracy · general knowledge",
    screenshot: "/puzzlecub/puzzlecub-sand.png",
    screenshotAlt: "Sand Quest gameplay — beach scene with a math question and trivia",
    accentVar: "--game-sand",
  },
  {
    slug: "alpha",
    iconKey: "alpha",
    name: "Alpha Quest",
    tagline: "Slide the letters, bring 'em home.",
    short:
      "Slide letters around a grid to spell words. Solo is a puzzle; vs-AI is a race against Doodle, Cipher, or Sphinx.",
    body:
      "Slide letters around a grid to spell as many valid words as you can. Solo mode is a contemplative puzzle. vs-AI mode is a race against one of three opponents — Doodle the Apprentice, Cipher the Journeyman, or Sphinx the Master. You play first with no AI visible; when you finish, your opponent plays the same shuffle. Beat their move count for a bonus.",
    skills: "Word formation · spatial reasoning · strategy",
    screenshot: "/puzzlecub/puzzlecub-alpha.png",
    screenshotAlt: "Alpha Quest vs-AI race against Doodle",
    accentVar: "--game-alpha",
  },
  {
    slug: "maze",
    iconKey: "maze",
    name: "Maze Quest",
    tagline: "Walk the maze, form the words.",
    short:
      "Walk a maze one cell at a time, picking up letters. The shape decides which words you can spell. No clock — only choices.",
    body:
      "A maze you walk one cell at a time, picking up letters as you go. The shape of the maze decides which words you can spell, and which paths cost you. Half puzzle, half pathfinding — the only Puzzlecub game where there is no clock, only choices.",
    skills: "Word formation · spatial reasoning · planning",
    screenshot: null,
    accentVar: "--game-maze",
  },
  {
    slug: "geo",
    iconKey: "geo",
    name: "Geo Quest",
    tagline: "Slot the piece, make the map.",
    short:
      "Assemble a region from its real piece shapes. Difficulty rises from shape, to name, to capital, to a single fact.",
    body:
      "Assemble a region — USA states, European countries, Oceania, South America, Africa — from their real piece shapes. Difficulty is set by what's on the tray card: Beginner shows the country shape, Medium shows the name, Hard shows only the capital, Expert shows a single fact. The board always shows the full outlined map; on Hard and Expert, you build outward, each new piece touching one already placed. Or race a Cartographer AI.",
    skills: "Geography · spatial reasoning · world knowledge",
    screenshot: "/puzzlecub/puzzlecub-geo.png",
    screenshotAlt: "Geo Quest — Oceania region intro card with tray pieces",
    accentVar: "--game-geo",
  },
  {
    slug: "stack",
    iconKey: "stack",
    name: "Stack Quest",
    tagline: "Solve the sum, stack the puck.",
    short:
      "Combine two numbers to hit an answer, drop a puck, and fill the tube before the rising water overflows.",
    body:
      "Pick an operation, then tap two grid numbers to make one of the three answer pills — each solve drops a puck into the tube on the right. Division splits the board into numerators and denominators for clean, whole answers. Beat the water rising on the left before it overflows the beaker. A hint lights the two cells that solve a pill; a slow-fill power-up buys you extra seconds. Easy to Hard sets the number range and the pace of the water.",
    skills: "Addition · subtraction · multiplication · division · mental math",
    screenshot: "/puzzlecub/puzzlecub-stack.png",
    screenshotAlt:
      "Stack Quest — stacking pucks by solving arithmetic before the water overflows",
    accentVar: "--game-stack",
  },
];

export function getGame(slug: string): Game | undefined {
  return GAMES.find(g => g.slug === slug);
}

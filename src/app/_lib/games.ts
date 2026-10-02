export interface Game {
  slug: string;
  name: string;
  tagline: string;
  short: string;
  body: string;
  skills: string;
  screenshot: string;
  screenshotAlt: string;
  icon: string;
  accentVar: string;
}
export interface StandaloneApp {
  appStoreComingSoon?: boolean;
  playStoreComingSoon?: boolean;
  slug: string;
  name: string;
  tagline: string;
  description: string;
  detail: string;
  note: string;
  icon: string;
  screenshot: string;
  appStoreUrl: string;
  playStoreUrl: string;
}
export const APP_STORE_URL = "https://apps.apple.com/app/id6768766852";
export const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.sumquest.app";
export const CHATURANG_URL = "https://neurantra.com/chaturang";
export const CHATURANG_APP_STORE_URL =
  "https://apps.apple.com/app/id6770267722";
export const CHATURANG_PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.chaturang.app";
export const GAMES: Game[] = [
  {
    slug: "math",
    name: "Tap the Answer",
    tagline: "Beat the drop. Catch the answer.",
    short:
      "Solve the equation and tap the right number before it hits the floor.",
    body: "Choose an operation and a difficulty, then catch the correct answer as the number tiles fall. Keep a streak going, protect your four chances, and chase your personal best. Correct answers, mistakes, and timeouts move straight into the next question. Prefer an untimed round? Choose the scenic route.",
    skills: "Addition · subtraction · multiplication · division · mixed rounds",
    accentVar: "--game-math",
    screenshot: "/puzzlecub/math.webp",
    screenshotAlt:
      "Tap the Answer gameplay in Puzzlecub’s cream-and-teal interface",
    icon: "/puzzlecub/math-icon.webp",
  },
  {
    slug: "sand",
    name: "Answer It",
    tagline: "Think it. Type it. Beat it.",
    short:
      "Enter your answer before time runs out. Keep your streak and protect your gems.",
    body: "Work through mental-math questions with an on-screen number pad, or compare values with a tap. Pick your challenge and round settings, protect your gems, and keep your streak alive. Quick feedback leads directly into the next question, so every round keeps moving.",
    skills: "Mental math · fractions · comparisons · quick thinking",
    accentVar: "--game-sand",
    screenshot: "/puzzlecub/sand.webp",
    screenshotAlt: "Answer It gameplay in Puzzlecub’s cream-and-teal interface",
    icon: "/puzzlecub/sand-icon.webp",
  },
  {
    slug: "stack",
    name: "Build the Sum",
    tagline: "Two numbers. One perfect sum.",
    short:
      "Pick two numbers, then tap the target they make. Hit targets against the clock.",
    body: "Find a pair of numbers that makes one of the target answers. Tap the two numbers and then their target to score, build a streak, and reveal fresh combinations. Explore addition, subtraction, multiplication, and division, with difficulty and timing options to suit your next round.",
    skills: "Number combinations · arithmetic · pattern recognition",
    accentVar: "--game-stack",
    screenshot: "/puzzlecub/stack.webp",
    screenshotAlt:
      "Build the Sum gameplay in Puzzlecub’s cream-and-teal interface",
    icon: "/puzzlecub/stack-icon.webp",
  },
  {
    slug: "word",
    name: "Find the Word",
    tagline: "Follow the clue. Find the word.",
    short:
      "Uncover a hidden word one letter at a time, before the clock or your guesses run out.",
    body: "Read the clue, choose letters, and work out the hidden word. Keep an eye on the timer and your remaining guesses, use a hint when you need a nudge, and move automatically to the next word when a puzzle is resolved. Choose your difficulty and round length, then see how far your vocabulary takes you.",
    skills: "Vocabulary · spelling · deduction",
    accentVar: "--game-word",
    screenshot: "/puzzlecub/word.webp",
    screenshotAlt:
      "Find the Word gameplay in Puzzlecub’s cream-and-teal interface",
    icon: "/puzzlecub/word-icon.webp",
  },
];
export const STANDALONE_APPS: StandaloneApp[] = [
  {
    slug: "fill-the-jar",
    name: "Fill the Jar",
    tagline: "A little space. A perfect fit.",
    description:
      "Fit geometric pieces into a jar with no gaps, or complete colorful picture puzzles. Rotate, place, undo, and enjoy the moment when everything clicks into place.",
    detail:
      "Explore shape puzzles and picture collections at your own pace. A placement preview helps you plan your next move, and hints can help when you get stuck.",
    note: "Free download; optional in-app purchases.",
    icon: "/apps/fill-the-jar-icon.webp",
    screenshot: "/apps/fill-the-jar.webp",
    appStoreUrl: "https://apps.apple.com/app/id6813074285",
    playStoreUrl:
      "https://play.google.com/store/apps/details?id=com.fillthejar.app",
  },
  {
    slug: "mapopia",
    appStoreComingSoon: true,
    name: "Mapopia",
    tagline: "A whole world, one piece at a time.",
    description:
      "Build real maps from colorful pieces. Explore places through shapes, names, capitals, and clues, with relaxed play or a timed challenge.",
    detail:
      "Discover 18 maps, switch between day and night, and tap placed pieces to learn their capitals and facts. Save an expedition and return later. Australia is free, with a limited trial of one additional map.",
    note: "Free Australia map; one-time Full Atlas purchase unlocks all maps.",
    icon: "/apps/mapopia-icon.webp",
    screenshot: "/apps/mapopia.webp",
    appStoreUrl: "https://apps.apple.com/app/id6816405706",
    playStoreUrl:
      "https://play.google.com/store/apps/details?id=com.mapopia.app",
  },
  {
    slug: "maze-words",
    name: "Maze Words",
    tagline: "Run the maze. Find the words.",
    description:
      "Trace connected letters through raised maze walls to discover words. Race the clock or take an untimed trail, then review the paths you missed.",
    detail:
      "Choose Easy, Medium, or Hard, follow a daily maze, and build your word-finding skills across a collection of original maze packs. Trace a continuous path or use tap-and-submit controls.",
    note: "Timed and relaxed rounds; core puzzles work offline.",
    icon: "/apps/maze-words-icon.webp",
    screenshot: "/apps/maze-words.webp",
    appStoreUrl: "https://apps.apple.com/app/id6816219346",
    playStoreUrl:
      "https://play.google.com/store/apps/details?id=com.mazewords.app",
  },
  {
    slug: "slide-and-sort",
    appStoreComingSoon: true,
    playStoreComingSoon: true,
    name: "Slide & Sort",
    tagline: "Little slides. Big smiles.",
    description:
      "Slide pastel letter and number tiles into place. Sort the alphabet, discover number patterns, or arrange a counting sequence.",
    detail:
      "Play a quiet solo puzzle or race Pip, your friendly AI buddy. Choose a timer, a move limit, both, or neither. Three puzzle modes and a warm wooden tray make every small move a satisfying discovery.",
    note: "Free, ad-supported play. No purchases or paid unlocks.",
    icon: "/apps/slide-and-sort-icon.webp",
    screenshot: "/apps/slide-and-sort.webp",
    appStoreUrl: "https://apps.apple.com/app/id6817987916",
    playStoreUrl:
      "https://play.google.com/store/apps/details?id=com.slideandsort.app",
  },
];
export function getGame(slug: string) {
  return GAMES.find((game) => game.slug === slug);
}
export function getStandaloneApp(slug: string) {
  return STANDALONE_APPS.find((app) => app.slug === slug);
}

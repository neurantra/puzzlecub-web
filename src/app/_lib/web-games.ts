export const webGames = [
  {
    slug: "chaturang",
    name: "Chaturang",
    category: "Ancient strategy",
    tagline: "Your place at the royal court.",
    description:
      "Meet an AI rival in the Indian ancestor of chess. Choose your level, draw a royal card, and make your opening move.",
    icon: "/chaturang/icon.webp",
    art: "/chaturang/court.png",
    details: "Three AI levels · Hints · Local statistics",
    color: "#123d3b",
  },
  {
    slug: "alphadoku",
    name: "Alphadoku",
    category: "Letter Sudoku",
    tagline: "A little logic. A lovely discovery.",
    description:
      "Find the hidden line in Classic, or settle into a bigger challenge with Mega. Letters take the place of numbers; every answer follows from logic.",
    icon: "/alphadoku/icon.png",
    art: "",
    details: "Classic & Mega · Daily challenges · Saved progress",
    color: "#24685b",
  },
  {
    slug: "mazewords",
    name: "Maze Words",
    category: "Words & mazes",
    tagline: "Run the maze. Find the words.",
    description:
      "Trace letters through open corridors, find hidden words, and collect a few surprises along the way. Choose a timed trail or take your time.",
    icon: "/apps/maze-words-icon.webp",
    art: "/apps/maze-words.webp",
    details: "Three difficulties · Relaxed play · Daily mazes",
    color: "#216d62",
  },
  {
    slug: "slide-and-sort",
    name: "Slide & Sort",
    category: "Sliding puzzles",
    tagline: "Little slides. Big smiles.",
    description:
      "Slide colorful letters and numbers into place. Play at your own pace or invite Pip, your friendly AI opponent, to join the challenge.",
    icon: "/apps/slide-and-sort-icon.webp",
    art: "/apps/slide-and-sort.webp",
    details: "Letters & numbers · Solo or AI · Optional limits",
    color: "#716038",
  },
  {
    slug: "mapopia",
    name: "Mapopia",
    category: "Geography puzzles",
    tagline: "A whole world, one piece at a time.",
    description:
      "Fit countries and regions into real maps. Discover shapes, names, and capitals as your next destination comes together.",
    icon: "/apps/mapopia-icon.webp",
    art: "/apps/mapopia.webp",
    details: "18 maps · Relaxed or timed · Saved expeditions",
    color: "#24566a",
  },
  {
    slug: "fillthejar",
    name: "Fill the Jar",
    category: "Shape puzzles",
    tagline: "A little space. A perfect fit.",
    description:
      "Rotate, arrange, and drop geometric pieces into a jar. Find room for every shape across a colorful journey, with no clock to hurry you.",
    icon: "/apps/fill-the-jar-icon.webp",
    art: "/apps/fill-the-jar.webp",
    details: "100 levels · Picture themes · No timer",
    color: "#75498a",
  },
] as const;
export type WebGame = (typeof webGames)[number];
export const gamePreferenceKey = "puzzlecub-selected-game";

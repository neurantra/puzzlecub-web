export const gameNames: Record<string, string> = {
  chaturang: "Chaturang",
  mazewords: "Maze Words",
  "slide-and-sort": "Slide & Sort",
  mapopia: "Mapopia",
  fillthejar: "Fill the Jar",

  "alphadoku-classic": "Classic Alphadoku",
  "alphadoku-mega": "Mega Alphadoku",
};

// Only fixed page categories reach storage. Never collect query strings or arbitrary paths.
export const pageNames: Record<string, string> = {
  "/": "Home",
  "/chaturang": "Chaturang",
  "/mazewords": "Maze Words",
  "/slide-and-sort": "Slide & Sort",
  "/mapopia": "Mapopia",
  "/fillthejar": "Fill the Jar",

  "/alphadoku": "Alphadoku overview",
  "/alphadoku/classic": "Classic Alphadoku",
  "/alphadoku/mega": "Mega Alphadoku",
  "/challenges": "Challenges",
  "/learn": "Learning library",
  "/learn/guide": "Learning guides",
  "/about": "About",
  "/privacy": "Privacy",
  "/terms": "Terms",
  "/credits": "Credits",
  "/download": "Downloads",
  "/mobile-apps": "Mobile apps",
  "/apps/app": "App details",
  "/games/game": "Game details",
};
export function pageCategory(path: string) {
  if (Object.hasOwn(pageNames, path)) return path;
  if (/^\/learn\/[^/]+$/.test(path)) return "/learn/guide";
  if (/^\/apps\/[^/]+$/.test(path)) return "/apps/app";
  if (/^\/games\/[^/]+$/.test(path)) return "/games/game";
  return null;
}
export function gameForPage(page: string) {
  if (
    ["/mazewords", "/slide-and-sort", "/mapopia", "/fillthejar"].includes(page)
  )
    return page.slice(1);
  return page === "/chaturang"
    ? "chaturang"
    : page === "/alphadoku/classic"
      ? "alphadoku-classic"
      : page === "/alphadoku/mega"
        ? "alphadoku-mega"
        : "";
}
export type Aggregate = {
  views: number;
  plays: number;
  completions: number;
  activeSeconds: number;
  playSeconds: number;
};
export type UsageReport = Aggregate & {
  gameViews: number;
  onlineEstimate: number;
  since: string;
  daily: (Aggregate & { day: string })[];
  pages: (Aggregate & { page: string })[];
};

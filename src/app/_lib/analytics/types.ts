export const gameNames: Record<string, string> = {
  "alphadoku-classic": "Classic Alphadoku",
  "alphadoku-mega": "Mega Alphadoku",
};

export type Visit = {
  id: string;
  startedAt: string;
  lastSeen: string;
  ip: string | null;
  entryPath: string;
  lastPath: string;
  referrer: string;
  device: string;
  activeSeconds: number;
  games: string[];
  completedGames: string[];
  online: boolean;
};

export type UsageReport = {
  visits: Visit[];
  total: number;
  players: number;
  online: number;
  averageActiveSeconds: number;
  completions: number;
  games: { id: string; players: number; completions: number }[];
};

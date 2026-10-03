import type { MetadataRoute } from "next";
import techniques from "./_lib/techniques.json";
export default function sitemap(): MetadataRoute.Sitemap {
  return [
    "",
    "/chaturang",
    "/alphadoku",
    "/alphadoku/classic",
    "/alphadoku/mega",
    "/challenges",
    "/learn",
    "/learn/getting-started",
    "/learn/mega-guide",
    "/learn/worked-example",
    "/about",
    "/privacy",
    "/terms",
    "/credits",
    ...techniques.map((t) => "/learn/" + t.slug),
  ].map((p) => ({
    url: "https://puzzlecub.com" + p,
    changeFrequency: p === "/challenges" ? "daily" : "monthly",
    priority: p === "" ? 1 : p.startsWith("/alphadoku") ? 0.9 : 0.6,
  }));
}

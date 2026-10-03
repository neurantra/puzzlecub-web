import type { MetadataRoute } from "next";
export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: "*", allow: "/", disallow: ["/classic-game/", "/admin", "/api/"] },
    sitemap: "https://puzzlecub.com/sitemap.xml",
  };
}

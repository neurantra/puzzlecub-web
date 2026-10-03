import type { MetadataRoute } from "next";
export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: "*",
        allow: "/",
        disallow: ["/classic-game/", "/chaturang-game/", "/admin", "/api/"],
      },
      {
        userAgent: "Mediapartners-Google",
        allow: "/",
        disallow: ["/admin", "/api/"],
      },
    ],
    sitemap: "https://puzzlecub.com/sitemap.xml",
  };
}

import type { NextConfig } from "next";
const nextConfig: NextConfig = {
  async headers() {
    return [
      {
        source: "/admin/:path*",
        headers: [
          { key: "Cache-Control", value: "private, no-store" },
          { key: "X-Robots-Tag", value: "noindex, nofollow" },
          { key: "X-Frame-Options", value: "DENY" },
        ],
      },
    ];
  },
  async redirects() {
    return [
      {
        source: "/games/alpha",
        destination: "/apps/slide-and-sort",
        permanent: true,
      },
      {
        source: "/games/maze",
        destination: "/apps/maze-words",
        permanent: true,
      },
      { source: "/games/geo", destination: "/apps/mapopia", permanent: true },
    ];
  },
};
export default nextConfig;

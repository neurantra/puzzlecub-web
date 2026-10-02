import type { NextConfig } from "next";
const nextConfig: NextConfig = {
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

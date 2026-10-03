import type { Metadata } from "next";
import { Plus_Jakarta_Sans } from "next/font/google";
import "./globals.css";
import { AdvertisingScript } from "./_components/Advertising";
import { adConfiguration } from "./_lib/ads";
import UsageAnalytics from "./_components/UsageAnalytics";

const jakarta = Plus_Jakarta_Sans({
  variable: "--font-jakarta",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  other: adConfiguration().client
    ? { "google-adsense-account": adConfiguration().client }
    : {},
  metadataBase: new URL("https://puzzlecub.com"),
  title: "PuzzleCub — Free puzzles and strategy games.",
  description:
    "Play Chaturang against AI and Classic or Mega Alphadoku free in your browser. Ancient strategy, letter Sudoku, and fresh puzzle challenges.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${jakarta.variable} h-full antialiased`}>
      <body className="min-h-full flex flex-col">
        {children}
        <UsageAnalytics />
        <AdvertisingScript />
      </body>
    </html>
  );
}

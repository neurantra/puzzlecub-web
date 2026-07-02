import type { Metadata } from "next";
import { Plus_Jakarta_Sans } from "next/font/google";
import "./globals.css";

const jakarta = Plus_Jakarta_Sans({
  variable: "--font-jakarta",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "Puzzlecub — Seven AI-driven games. One playful cub.",
  description:
    "Puzzlecub is a single app with seven games — Math, Word, Sand, Alpha, Maze, Geo, and Stack — bound together by a shared wallet, daily streak, and an AI that adapts to how you play. Made by Neurantra.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${jakarta.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}

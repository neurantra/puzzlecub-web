import CollectionGamePage from "../_components/CollectionGamePage";
export const metadata = {
  title: "Play Maze Words — Free online on PuzzleCub",
  description:
    "Play Maze Words free in your browser. No account, purchase, or download needed.",
  alternates: { canonical: "https://puzzlecub.com/mazewords" },
};
export default function Page() {
  return <CollectionGamePage slug="mazewords" />;
}

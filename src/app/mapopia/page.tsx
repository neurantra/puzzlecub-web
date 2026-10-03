import CollectionGamePage from "../_components/CollectionGamePage";
export const metadata = {
  title: "Play Mapopia — Free online on PuzzleCub",
  description:
    "Play Mapopia free in your browser. No account, purchase, or download needed.",
  alternates: { canonical: "https://puzzlecub.com/mapopia" },
};
export default function Page() {
  return <CollectionGamePage slug="mapopia" />;
}

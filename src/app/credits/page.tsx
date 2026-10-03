import { WebShell } from "../_components/WebShell";
export const metadata = {
  title: "Credits and open-source notices — PuzzleCub",
};
export default function Page() {
  return (
    <WebShell>
      <main id="main" className="article">
        <h1>Built with good tools.</h1>
        <p>
          PuzzleCub combines original game design and educational explanations
          with open-source frameworks and language resources.
        </p>
        <h2>Website and game frameworks</h2>
        <p>
          Next.js and React power the website and Mega interface. Flutter and
          Dart power Classic and Chaturang, sharing their mobile games’ logic
          and artwork. Classic’s Settings → About → View all licenses and
          notices contains its dependency notices. Chaturang’s About → Licenses
          includes its dependency and font notices.
        </p>
        <h2>Language resources</h2>
        <p>
          The Classic corpus draws on ESDB, WordNet and an editorial selection
          informed by wordfreq. Targets are checked for nine unique letters and
          allowed word lengths. Editorial review was AI-assisted. The resource
          licenses are preserved below.
        </p>
        <ul>
          {["ESDB", "WordNet", "wordfreq", "Fonts", "Nextjs", "React"].map(
            (n) => (
              <li key={n}>
                <a href={`/licenses/${n}.txt`}>{n} license and attribution</a>
              </li>
            ),
          )}
        </ul>
        <h2>Typography and icons</h2>
        <p>
          The website uses Plus Jakarta Sans. Classic includes openly licensed
          fonts and Material icons. Game icons and product imagery belong to the
          Neurantra game family.
        </p>
      </main>
    </WebShell>
  );
}

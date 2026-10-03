import { WebShell } from "../_components/WebShell";
export const metadata = {
  title: "PuzzleCub browser terms and play information",
};
export default function Page() {
  return (
    <WebShell>
      <main id="main" className="article">
        <h1>Playing on PuzzleCub</h1>
        <p>Browser edition · Updated October 3, 2026.</p>
        <h2>Free browser play</h2>
        <p>
          This edition offers unlimited Alphadoku puzzles and Chaturang games
          against AI without a purchase or account. Hints are free, except in
          unassisted Alphadoku Pro play. Display ads and interstitial ads
          between games may support free play when advertising is available.
        </p>
        <h2>Local progress</h2>
        <p>
          Progress is saved on the browser and device you use. We cannot restore
          it after browser storage is deleted. Chaturang stores local statistics
          and settings, but unfinished matches end when the page closes or
          reloads. Daily and weekly challenge schedules use UTC. Browser saves
          and mobile app purchases are separate.
        </p>
        <h2>Fair use and feedback</h2>
        <p>
          Enjoy the games for personal play. Please do not interfere with the
          service or misrepresent assisted results as unassisted records. Report
          bugs and accessibility issues to{" "}
          <a href="mailto:hello@neurantra.com">hello@neurantra.com</a>.
        </p>
        <h2>Publisher terms</h2>
        <p>
          PuzzleCub is published by Neurantra LLC. See{" "}
          <a href="https://neurantra.com/terms">Neurantra’s Terms of Use</a> for
          the publisher’s terms, and our{" "}
          <a href="/privacy">browser privacy information</a> for how this
          edition handles data.
        </p>
      </main>
    </WebShell>
  );
}

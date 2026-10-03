import { WebShell } from "../_components/WebShell";
export const metadata = { title: "PuzzleCub browser privacy information" };
export default function Page() {
  return (
    <WebShell>
      <main id="main" className="article">
        <h1>Your play. Your privacy.</h1>
        <p>Browser edition · Updated October 3, 2026.</p>
        <h2>What this browser edition stores</h2>
        <p>
          PuzzleCub stores game boards, notes, tutorial progress, target
          history, elapsed play time and local completion records in your
          browser. It uses that data to resume play and avoid repeating Classic
          targets. There is no player account or cloud game-save service in this
          edition.
        </p>
        <p>
          You can remove these records by clearing this site’s storage in your
          browser settings. This also deletes saved games. Private browsing may
          discard progress when a session ends.
        </p>
        <h2>Hosting and external links</h2>
        <p>
          Loading the website sends ordinary web requests to its hosting
          provider, which may process technical information such as IP addresses
          and request logs to deliver and secure the service. Mobile-store links
          and other external links take you to services with their own privacy
          practices.
        </p>
        <h2>Advertising and analytics</h2>
        <p>
          When optional usage analytics is enabled, we ask before collecting it.
          Declining does not affect your games. You can change your choice using
          the analytics control on this page. We record a random visit identifier,
          visit and last-seen times, page paths, referring website hostname,
          device category, games interacted with or completed, and estimated
          active time. If network-address collection is enabled, the visit also
          includes your IP address. We do not record puzzle entries or the full
          referring URL. There is no player sign-in or cross-device identity.
        </p>
        <p>
          Your choice is stored in this browser and the visit identifier is
          stored for the browser tab. Activity records are stored in our Neon
          database and are available through a password-protected owner dashboard.
          Vercel serves the website. IP addresses are removed after seven days
          and visit records after 90 days, by a daily cleanup (which may take up
          to an additional day). Security rate limits also use a keyed hash of
          the network address for short-lived abuse protection.
        </p>
        <p>
          Third-party advertising is not enabled. Before activating it, we will
          update these disclosures and provide applicable privacy controls. The
          browser edition does not use the mobile app’s billing or AdMob SDKs.
        </p>
        <h2>Contact and the publisher’s policy</h2>
        <p>
          Neurantra LLC publishes PuzzleCub. For broader company information,
          see{" "}
          <a href="https://neurantra.com/privacy">Neurantra’s Privacy Policy</a>
          . For a question about this browser edition, contact{" "}
          <a href="mailto:hello@neurantra.com">hello@neurantra.com</a>.
        </p>
      </main>
    </WebShell>
  );
}

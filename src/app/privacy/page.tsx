import { AdvertisingPrivacy } from "../_components/Advertising";
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
          targets. Chaturang stores local statistics, difficulty and cosmetic
          choices; it does not restore unfinished matches. There is no player
          account or cloud game-save service in this edition. The homepage
          remembers your selected game. Maze Words, Slide &amp; Sort, Mapopia,
          and Fill the Jar keep their own settings and progress separately. Maze
          Words, Slide &amp; Sort, and Fill the Jar also keep a local birth-year
          declaration to select a protected, ad-free experience for younger
          players. The birth year is not sent to our analytics or ad providers.
          Their unknown or protected profiles do not request ads on the game
          page.
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
        <h2>Anonymous usage statistics</h2>
        <p>
          We measure aggregate page views, game engagement, completions and
          active time to improve PuzzleCub. Measurement runs without an opt-in
          prompt. You can turn it off using the anonymous analytics control at
          the bottom of this page. Games work the same either way. We honor
          previous analytics declines and browser Do Not Track and Global
          Privacy Control signals.
        </p>
        <p>
          Our analytics stores totals by UTC day and fixed page category, not
          individual visits. We do not store IP addresses, visitor identifiers,
          device profiles, referrers, query strings, puzzle entries or browsing
          histories in analytics. Pages are not linked to a person or to each
          other. A fresh random delivery token prevents duplicate requests; it
          has no activity attached and expires after ten minutes. Anonymous
          heartbeat totals estimate active tabs and expire after two minutes.
        </p>
        <p>
          Vercel receives web requests and Neon stores the aggregate counters
          for up to 90 days. Counters are only used to improve this service and
          are not used for advertising or shared with advertising partners.
          Expired temporary records are removed on subsequent activity or by
          daily cleanup, so physical deletion may take up to one additional day.
          Your analytics preference is the only analytics value saved in browser
          storage. An older visit identifier is removed when this version loads.
          Separate security rate limits briefly use a keyed network-address hash
          to prevent abuse; it is never attached to analytics counters. Ordinary
          hosting/security logs and provider backups follow their own retention
          policies.
        </p>
        <h2>Advertising</h2>
        <p>
          Free play may be supported by Google AdSense display ads and H5 Games
          interstitial ads between games. Ads are only requested when
          advertising is activated and the required consent setup is in place.
          Google and its partners may process network and device information and
          use cookies or similar technologies to deliver, measure, and prevent
          fraud in ads, including non-personalized ads. Where required, Google’s
          consent message lets you manage advertising choices. These choices are
          separate from our anonymous usage statistics; declining ads does not
          prevent play. We do not send our anonymous analytics counters to
          Google.
        </p>
        <p>
          Use “Privacy & cookie settings” when available to revisit the consent
          message. Browser Do Not Track and Global Privacy Control signals
          disable our ad requests. Learn more about{" "}
          <a href="https://policies.google.com/technologies/partner-sites">
            how Google uses information from sites that use its services
          </a>
          . The browser edition does not use the mobile app’s billing or AdMob
          SDKs.
        </p>
        <AdvertisingPrivacy />
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

# PuzzleCub web v1.0

Browser-game hub for **puzzlecub.com**. The previous app-directory homepage is
preserved at `/mobile-apps`; `src/proxy.ts` serves it at `/` when the Host is
`puzzlecub.app` or `www.puzzlecub.app`. No DNS or production deployment was
changed by this implementation.

## Run locally

```sh
npm ci
npm run dev -- --port 3127
```

Open http://localhost:3127. Requires Node compatible with Next.js 16.

## Included

- Responsive game-discovery homepage, touch carousel with controls, interactive
  deduction warm-up, challenge links, local Continue links and mobile cross-promo.
- `/alphadoku/classic`: the existing Flutter Classic engine and controls, embedded
  in an HTML guide page. All 2,671 corpus targets, four levels, hidden-line rules,
  notes, undo, tutorial, techniques and local saves. No billing/ad SDKs.
- `/alphadoku/mega`: desktop/laptop only at 1200×700 CSS pixels or larger,
  with the full board and controls fitted to the viewport. A–Y, 25×25 Sudoku,
  5×5 boxes, four clue-density tiers,
  notes, undo, hints (not Pro), keyboard A–Y/arrows/Backspace/Space, pause,
  zoom, focused-box view, contrast, local saves, completion count and result copy.
- Mega generation runs in a worker. Removing only forced clues yields a reverse
  forced-move proof of uniqueness. These are **not human-technique difficulty
  ratings**. Tests validate units and replay the proof across 48 seeded boards.
- `/challenges`: UTC daily Medium Classic and Monday weekly Medium Mega. Classic
  uses date-specific save slots; Mega weekly has a slot separate from free play.
  Challenges begin October 2, 2026; archive links cover the last 30 days.
- HTML technique library, Classic/Mega guides, a worked candidate deduction,
  About/contact, browser privacy/terms, source acknowledgments, robots and sitemap.

## Build and source synchronization

```sh
npm run build          # verifies Classic asset fingerprint, then builds Next
npm run build:classic  # requires Flutter; validates corpus, compiles Classic
npm run build:all      # rebuilds Classic and Next
npm start
```

`web-game/` is a web-specific source snapshot of the released Alphadoku mobile
app. The mobile repository itself is unchanged. Generated `public/classic-game/`
assets are included for Node-only hosting (such as Vercel). When changing Flutter
source, rebuild and include the updated assets in the same change. The fingerprint
check rejects stale embedded code. Flutter renderer resources are self-hosted.
Keep native monetization changes out of this web snapshot. The corpus review
ledger and licenses are preserved in `web-game/data` and `web-game/assets`.

## Checks

```sh
npm test
npm run lint
npm run build
npm run test:e2e       # local server on 127.0.0.1:3127; uses installed Chrome
cd web-game && flutter test
```

Playwright covers desktop/mobile, discovery, Mega editing/notes/undo/save/resume,
Pro, completion, weekly determinism, Classic startup/resume/daily determinism,
content routes and `.app` hostname routing. Screenshots go to `test-results/`.

## Anonymous usage dashboard (Neon + Vercel)

`/admin` is password protected. It shows anonymous page views, playing game views,
views with a completed puzzle, active time, a daily chart/table, popular pages,
and an estimated active-tab count. Filter by game or 1/7/30/90 UTC calendar days.
Measurement starts automatically when enabled; there is no opt-in banner.

### What the numbers mean

- These are **page views, not unique people or visits**. Reloading or opening a
  second tab counts another view. No persistent or cross-page visitor identity exists.
- Classic/Mega page loads do not count as play. The first accepted game action in
  a page view increments playing views. The first solve increments views with a
  solve. Additional puzzles solved in that same page view are not separate counts.
- The game play rate is playing views divided by game-page views. It measures
  page-to-play engagement, not person-level conversion. Event counters use UTC
  dates; actions after midnight can fall on a different day than their page load.
- Active seconds count visible time with interaction in the last minute. Active
  play time follows game actions, pauses after a solve, and resumes on the next
  game action. Thinking without input for over a minute is excluded.
- Active tabs is a rough estimate: the anonymous heartbeat count in the last
  three complete 15-second buckets divided by three, rounded. It can lag by about
  a minute and fluctuates with network timing. It is not an exact headcount.
- Opt-outs, DNT/GPC, blockers, bots and offline requests affect totals. Signed-in
  admins are excluded. The `.app` mobile-app directory hostname is excluded.
- Different guide/app-detail paths are grouped into fixed categories. Query strings,
  arbitrary paths, referrers, device profiles and puzzle entries are never stored.

### Data and privacy design

Neon stores only daily counters by fixed page category. There are no visitor/IP
columns, individual event logs or browsing histories. No analytics ID is stored in
cookies, localStorage or sessionStorage. A different random **delivery** ID for
each request prevents retry duplicates; the receipt table stores only that ID
and its expiry, never its page or payload. Receipts expire after ten minutes;
heartbeat totals expire after two minutes. They are purged during collection and
by the daily retention job. Daily counters are kept for 90 UTC days.

A preference control on `/privacy` lets visitors stop measurement. It is the only
analytics value stored locally. Previous declines, Do Not Track and Global Privacy
Control are respected; old session IDs are removed on load. Legacy detailed
records are deleted by the migration, not blended into the new totals. Provider
backups and ordinary hosting/security logs have their own retention policies.

Rate limiting is separate security processing: collection uses a minute-rotating
keyed network hash, never attached to counters; admin login uses a separate key.
Expired rate-limit records are removed on subsequent requests or daily cleanup.

The design limits measurement to aggregate service-improvement statistics. It does
not assert that every jurisdiction grants the same consent exemption. It must not
be repurposed for advertising, profiling or individual tracking without reassessing
that design and updating the disclosures and controls.

### Configure production or upgrade

1. Use a dedicated PuzzleCub Neon database and owning role. Keep PlaneSane data
   and credentials separate. Store its SSL connection string as `DATABASE_URL`.
2. Run [`database/analytics.sql`](database/analytics.sql) as that owner. This is
   idempotent for fresh installs and upgrades. **It deletes legacy detailed visit
   records**, replaces their old write function with a no-op during rollout, and
   installs aggregate tables/functions. Apply before deploying the new code.
3. Configure these in the PuzzleCub Vercel project:

   | Variable | Value |
   | --- | --- |
   | `DATABASE_URL` | PuzzleCub Neon connection string |
   | `ADMIN_PASSWORD` | Unique passphrase, at least 16 characters |
   | `ADMIN_SESSION_SECRET` | Independent random secret, at least 32 characters |
   | `CRON_SECRET` | Independent random secret for daily cleanup |
   | `NEXT_PUBLIC_ANALYTICS_ENABLED` | `true` |

   `ANALYTICS_COLLECT_IP` is obsolete and ignored, even if still set to `true` in
   Vercel. Remove it when convenient. `.env.example` documents optional origin and
   trusted-IP-header settings used for security. Never put database credentials or
   admin secrets in public environment variables, source control or chat.
4. Deploy through the existing Vercel workflow. The public enable flag is a build-
   time setting. Use a separate Neon database/branch for previews, or disable
   preview measurement. The migration briefly makes old admin reports empty until
   the new deployment is live. Existing old tabs cannot recreate visit records.
5. Open `/admin`, then use a separate browser/private window to visit a game page
   and make a move. The dashboard should increment views and playing views without
   any prompt. Check Vercel's daily `/api/cron/usage-retention` job is succeeding.
   `CRON_SECRET` authenticates it; a failed job should be investigated.

The admin cookie is HttpOnly, Secure in production and SameSite=Strict, and expires
in eight hours. Password/secret rotation invalidates existing sessions. Both page
and API verify authentication and never cache private responses. Neon-backed login
limits work across Vercel instances. Database errors fail closed.

### Tests and future games

`npm test` runs the real SQL in PGlite, including upgrade deletion, duplicate
handling, retention, date/game filters, online estimates and permissions. To run
browser tests against an isolated in-memory database, start this local server:

```sh
PUZZLECUB_TEST_DATABASE=1 \
DATABASE_URL=postgresql://test:test@puzzlecub-test.neon.tech/puzzlecub \
ADMIN_PASSWORD=local-analytics-test-password \
ADMIN_SESSION_SECRET=local-test-secret-at-least-32-characters \
NEXT_PUBLIC_ANALYTICS_ENABLED=true ANALYTICS_TRUSTED_IP_HEADER=x-test-ip \
NODE_OPTIONS='--import=./tests/neon-fixture.mjs' \
node node_modules/next/dist/bin/next dev --port 3149
```

Then run in another terminal:

```sh
PUZZLECUB_TEST_DATABASE=1 PLAYWRIGHT_BASE_URL=http://127.0.0.1:3149 \
npx playwright test
```

The fake connection is intercepted by the test fixture; never deploy the fixture.
Tests check automatic counting, no visitor storage, opt-outs/privacy signals,
admin protection and actual Classic/Mega gameplay. For future games update
`gameNames`, `pageNames`, `gameForPage`, and the SQL game-to-page mappings, and emit
`trackGame(id)` on a real action or `trackGame(id, true)` on a solve. Neither puzzle
IDs nor visitor IDs should be added to collection payloads.

Search Console complements this dashboard with Google queries, impressions and
clicks. It does not provide these on-site engagement measures.

## Before public launch

1. Review both games and editorial pages. Mega is an initial clue-density beta;
   calibrate advanced human-solving difficulty separately.
2. Attach `puzzlecub.com` and `puzzlecub.app` to the intended deployment, configure
   DNS/HTTPS, verify host routing and redirects, then verify each site's canonical
   URLs. App directory source is preserved; old mobile store statuses should be
   checked by the owner before publishing the new directory domain.
3. Update the challenge launch date if actual public launch moves. Keep the seed
   algorithm stable after launch or version it to preserve challenge identities.
4. Check publisher legal coverage for this web edition and actual hosting provider.
5. Verify crawler access and Search Console. Do not submit to AdSense until the
   playable site and content have passed public-beta review.

## Chaturang and the games homepage

The homepage features visible Chaturang and Alphadoku cards. `/chaturang` embeds
our Flutter browser edition, adapted from the mobile source without changing that
repository. See [chaturang-game/README.md](chaturang-game/README.md) for provenance,
worker architecture, browser differences and rebuilding. Run `npm run build:chaturang`
after changes; commit the generated `public/chaturang-game` assets. `npm run build:all`
builds both Flutter games and then Next. Chaturang keeps the mobile UI, AI, card-pick
flow, hints, rules and local cosmetic progression, with unlimited free AI matches.
No purchases or online multiplayer. Unfinished Chaturang matches are not saved.

Apply the updated `database/analytics.sql` to include Chaturang in aggregate game
filters. A playing view requires a real human move. A finished view includes a
terminal match after human play, including forfeits. The dashboard is aggregate,
not a count of unique people or of every match in a multi-match page view.

## AdSense and H5 Games Ads activation

Ads are implemented but **off by default**. The game works without ad approval,
consent, ad inventory or an unblocked SDK. No fabricated publisher or slot IDs are
shipped. Anonymous first-party analytics remains independent of advertising consent.

1. Add puzzlecub.com in AdSense. Deploy `public/ads.txt`, which contains publisher
   `pub-5992130091579926` and is served at `/ads.txt` without environment variables.
   Verify using the ads.txt method and submit the site for review. Also set the
   server environment variable `ADSENSE_CLIENT=ca-pub-5992130091579926` for the
   verification meta tag and future ad requests. Ads remain off until activated.
2. Create two responsive display units: a content unit (`ADSENSE_CONTENT_SLOT`)
   and gameplay unit (`ADSENSE_GAMEPLAY_SLOT`). Use the numeric IDs, not pasted HTML.
   Turn **Auto ads off** for this site (including anchors and vignettes) so Google
   cannot add overlays or placements near controls outside these manual slots.
3. In AdSense Privacy & messaging, publish Google's certified consent message for
   applicable regions and configure applicable US state privacy messages. Verify
   the message and revocation link on a preview before setting `ADS_CONSENT_READY=true`.
   The SDK consumes CMP signals; non-personalized requests do not bypass consent.
   “Privacy & cookie settings” appears when Google's consent API is available.
4. Apply separately for [H5 Games Ads](https://adsense.google.com/start/h5-game-ads-apply/).
   Normal AdSense display approval alone does not grant H5 access. Set
   `H5_ADS_ENABLED=true` only after that access is granted.
5. Once approved and tested, set `ADS_ENABLED=true`, keep `ADS_TEST_MODE=false`,
   and redeploy. Display ads can launch independently while H5 stays disabled.
   Never click your own live ads.

For local/preview SDK checks use your publisher ID with `ADS_ENABLED=true`,
`H5_ADS_ENABLED=true`, and `ADS_TEST_MODE=true`. This requests Google's test mode;
never promote those preview settings to production. Our Playwright tests substitute
an SDK entirely and generate no requests to Google. External approval and actual
regional CMP behavior must still be verified with your real account before live ads.

Display placements follow the rich static content and sit at least 160px beyond
the game area. Mobile Classic keeps a full viewport for play and allows scrolling
down to its separated ad. No ads are on the admin or legal pages. Unfilled display
units collapse. Interstitials use H5 `next` placements after actual play, never on
first entry or during a move. They wait at least 60 seconds after page load and
at least three minutes between requests; Google's own cap and inventory may skip
more. The API is loaded inside each Flutter game document as Google requires.
Games pause/mute before the request and continue on `adBreakDone`, including no-fill;
a blocked/not-ready SDK is skipped immediately. Ads do not contribute to active
play time. Hints remain free and are not gated by rewarded ads.

No accounts, cloud saves, public leaderboard or push/email notifications are
implemented. Browser storage can be cleared and progress is device-local. Classic
can continue in an already-loaded tab offline; this is not an installable offline PWA.

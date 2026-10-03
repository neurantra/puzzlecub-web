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

## Private usage dashboard (Neon + Vercel)

`/admin` provides password-protected visit records, game filters, engagement
totals, active time, last seen, estimated online status, and optional IP addresses.
Classic and Mega report actual puzzle actions rather than counting page loads
as play. There are no player accounts: the date is **visit started**, not sign-in.
Visitors must opt in to usage analytics. Signed-in admin requests are excluded.
Tracking starts when enabled; earlier usage cannot be reconstructed.

### Configure production

1. In your existing Neon account, create a dedicated **PuzzleCub database** and
   preferably its own owning role. Keep PlaneSane's tables and credentials separate.
   Use the Neon connection string for that database as `DATABASE_URL`.
2. Run [`database/analytics.sql`](database/analytics.sql) in the Neon SQL editor,
   connected to that database as the same role the app will use. It creates the
   private `puzzlecub_usage` schema and server-only functions. No database URL or
   admin secret goes into a `NEXT_PUBLIC_` variable.
3. In the PuzzleCub Vercel project's environment settings, configure:

   | Variable | Value |
   | --- | --- |
   | `DATABASE_URL` | PuzzleCub Neon connection string with SSL |
   | `ADMIN_PASSWORD` | Unique random password, at least 16 characters |
   | `ADMIN_SESSION_SECRET` | Independent random value, at least 32 characters |
   | `CRON_SECRET` | Independent random value for the retention job |
   | `NEXT_PUBLIC_ANALYTICS_ENABLED` | `true` after the schema is installed |
   | `ANALYTICS_COLLECT_IP` | `true` for the requested IP column; otherwise `false` |

   Generate each secret separately with `openssl rand -hex 32`, and keep it in
   your password manager and Vercel, not Git or chat. `.env.example` lists optional
   settings. For local use copy it to `.env.local`. Vercel's trusted client-IP
   header is detected automatically. Outside Vercel, IP collection is disabled
   unless a trusted proxy header is explicitly configured.
4. Deploy normally through your existing Vercel workflow. The public analytics
   flag is read at build time, so changing it requires a new deployment. Use a
   separate Neon database/branch for previews or leave preview analytics disabled.
5. Open `/admin`, sign in, then use a separate browser/private window to opt in
   and make a game move. Refresh the admin report to verify the visit and game.
   Monitor Vercel's daily `/api/cron/usage-retention` job: it removes IPs older
   than seven days and records older than 90 days. Cleanup runs daily; the report
   independently hides expired IPs. Vercel sends `CRON_SECRET` as a bearer token.

The admin cookie is HttpOnly, Secure in production, SameSite=Strict, and expires
after eight hours. Changing the password or session secret invalidates existing
sessions. Both page rendering and the data API verify authentication; responses
are uncached. Login limits are stored in Neon and shared across Vercel instances.
Database failure denies login and reports an error, rather than bypassing checks.

### Reading the numbers and extending games

- One visit is a browser-tab session; 30 minutes without interaction starts a
  fresh visit on the next interaction. These are visits, **not unique people**.
- A heartbeat runs every 15 seconds while the page is visible. Online means a
  visible heartbeat in the last 45 seconds; closing a tab is best effort.
- Active time counts visible seconds with an interaction within the previous
  minute. Visit span is the time between first and last reports, including breaks.
  Neither is an exact measurement of attention. Game thinking time with no
  interaction for over a minute will not count as active time.
- Games played and completions are distinct games within each visit, not a
  count of every puzzle attempt. The table shows the latest 500 matching visits;
  summary totals cover the whole selected period. Data comes from browsers and
  can be blocked or spoofed; this is product analytics, not an audit log.
- Referrer host and device category help explain acquisition and usability.
  IP addresses can be shared or change and should not identify individual players.
  Visits are not linked across devices or browser tabs.
- Add future games to `src/app/_lib/analytics/types.ts`, then call `trackGame(id)`
  for an accepted game action and `trackGame(id, true)` for completion. No schema
  change is needed. The Classic iframe uses a same-origin/source-checked bridge.
- Useful next additions: difficulty, individual game starts/completions and
  completion rate, device/country breakdowns, and an aggregate daily trend. Returning
  visitor analysis would require a separate, longer-lived consented identifier.
- Use Google Search Console alongside this dashboard for search queries,
  impressions, clicks, and search performance. It does not supply individual
  gameplay histories or IP addresses.

### Analytics integration tests without Neon credentials

`npm test` runs the analytics schema on an in-memory PostgreSQL engine (PGlite),
including retry safety, game filtering, online expiry, rate limits, permissions,
and retention. For end-to-end tests, start an isolated test server:

```sh
PUZZLECUB_TEST_DATABASE=1 \
DATABASE_URL=postgresql://test:test@puzzlecub-test.neon.tech/puzzlecub \
ADMIN_PASSWORD=local-analytics-test-password \
ADMIN_SESSION_SECRET=local-test-secret-at-least-32-characters \
NEXT_PUBLIC_ANALYTICS_ENABLED=true ANALYTICS_COLLECT_IP=true \
ANALYTICS_TRUSTED_IP_HEADER=x-test-ip \
NODE_OPTIONS='--import=./tests/neon-fixture.mjs' \
node node_modules/next/dist/bin/next dev --port 3149
```

In another terminal:

```sh
PUZZLECUB_TEST_DATABASE=1 PLAYWRIGHT_BASE_URL=http://127.0.0.1:3149 \
npx playwright test tests/browser/analytics.spec.ts
```

These credentials and the fake Neon endpoint are test-only. The fixture intercepts
only that endpoint and runs the real SQL locally. Never enable the fixture on a
deployment. The existing game browser suite remains `npm run test:e2e`.

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

## Monetization boundary

**Ads and third-party marketing analytics are intentionally not active.** Optional
first-party usage analytics is available through the admin setup above. No fake publisher
ID, live ad request, paywall, billing SDK, or consent bypass is included. Gameplay
is unlimited and hints are free during this launch beta. Pro stays unassisted.

AdSense publisher/site approval, web CMP configuration and actual slot IDs remain
external setup. Reserve display placements away from controls after consent is
implemented; do not let ad loading shift the board. Rewarded hints require H5 Games
Ads access (separate from standard display ad integration). Always support no-fill
without blocking a saved game. Update the privacy page when these are enabled.

This is a local implementation, not an AdSense approval or published launch.
No accounts, cloud saves, public leaderboard or push/email notifications are
implemented. Browser storage can be cleared and progress is device-local. Classic
can continue in an already-loaded tab offline; this is not an installable offline PWA.

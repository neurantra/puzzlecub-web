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
- `/alphadoku/mega`: A–Y, 25×25 Sudoku, 5×5 boxes, four clue-density tiers,
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

**Ads and third-party analytics are intentionally not active.** No fake publisher
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

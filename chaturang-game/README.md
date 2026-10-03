# Chaturang browser edition

Source snapshot from `~/dev/chaturang-app`, version 2.0.3+23, commit
`0f0b410535c89ac4a4ae51d6d1f2e27bc721cba9`. The mobile repository is unchanged.
The court, card ceremony, sculpted pieces, board, rules, settings, difficulty,
move history, local stats, cosmetic progression, and results use the mobile UI.

Browser changes:

- Unlimited AI games and free hints. No RevenueCat, AdMob, Firebase, remote vault,
  online matchmaking, mobile release-policy check, or purchase dependencies.
  Earned coins only unlock local cosmetic appearances; they cannot be purchased.
- The same engine runs in a persistent browser worker. Its opening book and
  precomputed KR-K tablebase are bundled; UI/hint calls never search on the UI thread.
  A failed/timed-out worker is terminated and an AI turn recovers with a legal move.
- Position hashes use signed 64-bit `BigInt` to preserve the mobile opening book,
  repetition detection, and transposition validation when compiled to JavaScript.
- Local storage keys are namespaced, separate from Alphadoku. An unfinished match
  is not persisted; leaving/reloading ends it, as disclosed on the play page.
- Accessible board-square and card labels plus keyboard activation.
- Same-origin game-action messages contain only completion state. Anonymous
  analytics runs in the parent. No move log, player ID or difficulty is transmitted.
- Natural next-game transitions call the shared `/game-ads.js` H5 adapter, with
  clocks stopped and audio muted. No ad SDK calls are made without site activation.

From the site root, run `npm run build:chaturang` with Flutter and Dart available.
Commit both this source and `public/chaturang-game/`; Vercel needs only Node.
The site's prebuild verifies the source fingerprint. Do not edit generated assets.

Verification: `flutter analyze`, `flutter test` in this directory, and the site's
Playwright Chaturang test (real compiled worker, human move, AI reply, hint, restart,
mobile layout, analytics). Mobile billing/network tests are intentionally not copied.

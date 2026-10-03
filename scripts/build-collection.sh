#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
for game in mazewords slide-and-sort mapopia fillthejar; do
  (
    cd "$game-game"
    flutter pub get
    flutter build web --release --no-web-resources-cdn --base-href="/$game-game/" --dart-define=ENABLE_FIREBASE=false --dart-define=ENABLE_VAULT=false --dart-define=ENABLE_PURCHASES=false --dart-define=ENABLE_ADS=false --dart-define=ENABLE_AD_PREVIEW=false
  )
  mkdir -p "public/$game-game"
  rsync -a --delete "$game-game/build/web/" "public/$game-game/"
done
mkdir -p public/maze-packs
rsync -a --delete mazewords-game/pack_hosting/ public/maze-packs/
node scripts/collection-fingerprint.mjs --write

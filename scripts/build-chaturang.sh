#!/bin/sh
set -eu
cd "$(dirname "$0")/../chaturang-game"
flutter pub get
flutter build web --release --no-web-resources-cdn --base-href=/chaturang-game/
dart compile js -O2 --no-source-maps tool/ai_worker.dart -o build/web/ai_worker.js
rm -f build/web/ai_worker.js.deps build/web/ai_worker.js.map
dart run tool/tablebase.dart
cd ..
mkdir -p public/chaturang-game
rsync -a --delete chaturang-game/build/web/ public/chaturang-game/
node scripts/chaturang-fingerprint.mjs --write

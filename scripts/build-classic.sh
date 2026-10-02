#!/bin/sh
set -eu
cd "$(dirname "$0")/../web-game"
python3 tool/build_corpus.py --check --release
flutter pub get
flutter build web --release --no-web-resources-cdn --base-href=/classic-game/
cd ..
mkdir -p public/classic-game
rsync -a --delete web-game/build/web/ public/classic-game/

node scripts/classic-fingerprint.mjs --write

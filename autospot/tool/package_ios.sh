#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
APP="$ROOT/build/ios/iphoneos/Runner.app"
OUT="$ROOT/releases/AutoSpot-1.4.0-ios.ipa"
if [[ ! -d "$APP" ]]; then
  echo "Runner.app not found. Build first: flutter build ios --release --no-codesign" >&2
  exit 1
fi
STAGE="$(mktemp -d)"
mkdir -p "$STAGE/Payload" "$ROOT/releases"
cp -R "$APP" "$STAGE/Payload/AutoSpot.app"
(
  cd "$STAGE"
  zip -qry "$OUT" Payload
)
rm -rf "$STAGE"
echo "Wrote $OUT"
ls -lh "$OUT"

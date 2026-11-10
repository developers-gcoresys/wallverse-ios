#!/usr/bin/env bash
# Fails when the iOS bundle has drifted from the canonical Android content.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="${1:-$ROOT/../wallverse-android/app/src/main/assets}"

if [[ ! -f "$SOURCE/verses.json" ]]; then
  echo "Canonical verse list not found at $SOURCE/verses.json" >&2
  echo "Usage: tools/check-content.sh [/path/to/wallverse/android/assets]" >&2
  exit 1
fi

if cmp -s "$SOURCE/verses.json" "$ROOT/App/Resources/verses.json"; then
  echo "iOS WallVerse content matches $SOURCE"
else
  echo "DRIFT: App/Resources/verses.json differs from $SOURCE/verses.json" >&2
  echo "Run tools/sync-content.sh to update the bundle." >&2
  exit 1
fi

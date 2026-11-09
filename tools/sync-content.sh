#!/usr/bin/env bash
# Copies the reviewed verse list from the Android app into the iOS bundle so
# the two platforms never drift silently.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="${1:-$ROOT/../wallverse-android/app/src/main/assets}"
DESTINATION="$ROOT/App/Resources"

if [[ ! -f "$SOURCE/verses.json" ]]; then
  echo "verses.json not found at $SOURCE/verses.json" >&2
  echo "Usage: tools/sync-content.sh [/path/to/wallverse/android/assets]" >&2
  exit 1
fi

cp "$SOURCE/verses.json" "$DESTINATION/verses.json"
echo "Synced $SOURCE/verses.json -> $DESTINATION/verses.json"

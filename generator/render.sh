#!/usr/bin/env bash
# Regenerate the chessboard background PNG from chess-cyber.html using headless
# Chrome/Chromium. The pre-rendered PNG already ships in ../ghostty/backgrounds/ - you
# only need this if you want to tweak the board itself.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${1:-$DIR/../ghostty/backgrounds/ChessKing.png}"

CHROME=""
for c in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/Applications/Chromium.app/Contents/MacOS/Chromium" \
  "$(command -v google-chrome 2>/dev/null || true)" \
  "$(command -v google-chrome-stable 2>/dev/null || true)" \
  "$(command -v chromium 2>/dev/null || true)" \
  "$(command -v chromium-browser 2>/dev/null || true)"; do
  if [ -n "$c" ] && [ -x "$c" ]; then CHROME="$c"; break; fi
done

if [ -z "$CHROME" ]; then
  echo "No Chrome/Chromium found. Install one, or just use the pre-rendered PNG in ghostty/backgrounds/." >&2
  exit 1
fi

"$CHROME" --headless=new --hide-scrollbars --force-device-scale-factor=1 \
  --screenshot="$OUT" --window-size=2560,1600 "file://$DIR/chess-cyber.html"

echo "Rendered board -> $OUT"

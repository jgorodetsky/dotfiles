#!/usr/bin/env bash
# ChessKing - Ghostty theme installer.
# Copies the theme + background image into your Ghostty config dir and adds the
# required config lines. Safe to re-run (idempotent).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GHOSTTY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
THEMES_DIR="$GHOSTTY_DIR/themes"
CONFIG="$GHOSTTY_DIR/config"
BG_DST="$GHOSTTY_DIR/chess-king-cyber.png"

echo "Installing ChessKing into $GHOSTTY_DIR"
mkdir -p "$THEMES_DIR"

cp "$REPO_DIR/ghostty/themes/ChessKing" "$THEMES_DIR/ChessKing"
cp "$REPO_DIR/ghostty/chess-king-cyber.png" "$BG_DST"

MARK_START="# >>> ChessKing (managed) >>>"
MARK_END="# <<< ChessKing (managed) <<<"

BLOCK="$MARK_START
theme = ChessKing
background-image = $BG_DST
background-image-opacity = 0.6
background-image-position = center
background-image-fit = cover
background-image-repeat = false
$MARK_END"

touch "$CONFIG"
if grep -qF "$MARK_START" "$CONFIG"; then
  echo "ChessKing block already present in $CONFIG - leaving it untouched."
else
  printf '\n%s\n' "$BLOCK" >> "$CONFIG"
  echo "Added ChessKing config block to $CONFIG"
fi

echo
echo "Done. Reload Ghostty:  macOS = Cmd+Shift+,   Linux = Ctrl+Shift+,"
echo "(or fully restart Ghostty if the background image doesn't appear)"

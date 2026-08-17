#!/usr/bin/env bash
# ChessKing + gtheme installer.
# Installs the ChessKing theme and its board, the gtheme theme picker, and points your
# Ghostty config at ChessKing. Safe to re-run (idempotent).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GHOSTTY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
THEMES_DIR="$GHOSTTY_DIR/themes"
BG_DIR="$GHOSTTY_DIR/backgrounds"

# config: prefer an existing macOS App Support config, else XDG (same as gtheme)
CONFIG=""
for c in "$HOME/Library/Application Support/com.mitchellh.ghostty/config" "$GHOSTTY_DIR/config"; do
  [ -f "$c" ] && { CONFIG="$c"; break; }
done
[ -z "$CONFIG" ] && CONFIG="$GHOSTTY_DIR/config"

echo "Installing into $GHOSTTY_DIR"
mkdir -p "$THEMES_DIR" "$BG_DIR"

cp "$REPO_DIR/ghostty/themes/ChessKing"           "$THEMES_DIR/ChessKing"
cp "$REPO_DIR/ghostty/backgrounds/ChessKing.png"  "$BG_DIR/ChessKing.png"
cp "$REPO_DIR/ghostty/backgrounds/ChessKing.opts" "$BG_DIR/ChessKing.opts"
cp "$REPO_DIR/ghostty/gtheme"                     "$GHOSTTY_DIR/gtheme"
chmod +x "$GHOSTTY_DIR/gtheme"

MARK_START="# >>> ChessKing (managed) >>>"
MARK_END="# <<< ChessKing (managed) <<<"
BLOCK="$MARK_START
theme = ChessKing
background-image = $BG_DIR/ChessKing.png
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
echo "Installed:"
echo "  theme    $THEMES_DIR/ChessKing"
echo "  board    $BG_DIR/ChessKing.png (+ .opts)"
echo "  gtheme   $GHOSTTY_DIR/gtheme"
echo
echo "Reload Ghostty (macOS: Cmd+Shift+,  Linux: Ctrl+Shift+,) or restart it."
echo "Switch themes anytime:  $GHOSTTY_DIR/gtheme   (needs fzf: brew install fzf)"

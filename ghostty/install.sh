#!/usr/bin/env bash
# ChessKing + gtheme installer (theme only).
# Installs the ChessKing theme, its board, and the gtheme picker, and points your
# Ghostty config at ChessKing. Safe to re-run (idempotent).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

cp "$DIR/themes/ChessKing"           "$THEMES_DIR/ChessKing"
cp "$DIR/backgrounds/ChessKing.png"  "$BG_DIR/ChessKing.png"
cp "$DIR/backgrounds/ChessKing.opts" "$BG_DIR/ChessKing.opts"
cp "$DIR/gtheme"                     "$GHOSTTY_DIR/gtheme"
chmod +x "$GHOSTTY_DIR/gtheme"

# make gtheme runnable as a bare command: symlink into ~/.local/bin (on PATH via .zprofile)
mkdir -p "$HOME/.local/bin"
ln -sf "$GHOSTTY_DIR/gtheme" "$HOME/.local/bin/gtheme"

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
echo "Switch themes anytime:  gtheme   (command via ~/.local/bin; needs fzf)"

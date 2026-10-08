#!/usr/bin/env bash
# ghostty themes + gtheme installer.
# Installs every theme in themes/ (ChessKing, cadillac-*), the ChessKing board, and the
# gtheme picker, and points your Ghostty config at ChessKing. Safe to re-run (idempotent).
# Never clobbers: a file that differs from the repo copy is kept as <file>.bak-<timestamp>.
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

STAMP="$(date +%Y%m%d%H%M%S)"
place(){ # copy $1 to $2; keep a differing existing file as a timestamped .bak
  if [ -e "$2" ] && ! cmp -s "$1" "$2"; then mv "$2" "$2.bak-$STAMP"; echo "  kept your $2 as $2.bak-$STAMP"; fi
  [ -e "$2" ] || cp "$1" "$2"
}

echo "Installing into $GHOSTTY_DIR"
mkdir -p "$THEMES_DIR" "$BG_DIR"

for t in "$DIR"/themes/*; do place "$t" "$THEMES_DIR/${t##*/}"; done
place "$DIR/backgrounds/ChessKing.png"  "$BG_DIR/ChessKing.png"
place "$DIR/backgrounds/ChessKing.opts" "$BG_DIR/ChessKing.opts"
place "$DIR/gtheme"                     "$GHOSTTY_DIR/gtheme"
chmod +x "$GHOSTTY_DIR/gtheme"

# make gtheme runnable as a bare command: symlink into ~/.local/bin (on PATH via .zprofile)
mkdir -p "$HOME/.local/bin"
LINK="$HOME/.local/bin/gtheme"
case "$(readlink "$LINK" 2>/dev/null || true)" in
  "$GHOSTTY_DIR/gtheme"|"$DIR/gtheme") ;;
  *) [ -e "$LINK" ] || [ -L "$LINK" ] && { mv "$LINK" "$LINK.bak-$STAMP"; echo "  kept your $LINK as $LINK.bak-$STAMP"; } ;;
esac
ln -sfn "$GHOSTTY_DIR/gtheme" "$LINK"

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
echo "  themes   $THEMES_DIR/ ($(ls "$DIR/themes" | tr '\n' ' '))"
echo "  board    $BG_DIR/ChessKing.png (+ .opts)"
echo "  gtheme   $GHOSTTY_DIR/gtheme"
echo
echo "Reload Ghostty (macOS: Cmd+Shift+,  Linux: Ctrl+Shift+,) or restart it."
echo "Switch themes anytime:  gtheme   (command via ~/.local/bin; needs fzf)"

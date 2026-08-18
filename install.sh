#!/usr/bin/env bash
# fresh-machine setup — one and done. idempotent: each step skips what's already there.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. xcode command line tools
xcode-select -p >/dev/null 2>&1 || xcode-select --install

# 2. homebrew — install if missing, then load it into THIS shell
if ! command -v brew >/dev/null 2>&1; then
  echo "installing homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [ -x "$b" ] && { eval "$("$b" shellenv)"; break; }
done

# 3. packages
brew bundle --file="$DIR/Brewfile"

# 4. link shell + git config (stow). back up any real file in the way first.
if command -v stow >/dev/null 2>&1; then
  for f in .zshrc .zprofile .gitconfig; do
    t="$HOME/$f"
    [ -e "$t" ] && [ ! -L "$t" ] && mv "$t" "$t.pre-dotfiles.bak"
  done
  stow --dir="$DIR" --target="$HOME" --ignore='example$' --restow shell git
else
  echo "stow not found; run 'brew install stow' then re-run to link configs"
fi

# 5. per-machine git identity reminder (never tracked in this repo)
if [ ! -f "$HOME/.gitconfig.local" ]; then
  echo "note: set your git identity in ~/.gitconfig.local (see git/.gitconfig.local.example)"
fi

# 6. macos defaults (key repeat, file extensions, screenshots -> ~/Screenshots)
bash "$DIR/macos/defaults.sh"

# 7. claude code cli — not a brew package. install it separately if missing.
command -v claude >/dev/null 2>&1 || \
  echo "note: install Claude Code separately (native installer; not in Homebrew)"

# 8. claude commands
mkdir -p "$HOME/.claude/commands"
cp "$DIR"/claude/commands/*.md "$HOME/.claude/commands/" 2>/dev/null || true

# 9. ghostty theme + gtheme picker
[ -x "$DIR/ghostty/install.sh" ] && "$DIR/ghostty/install.sh"

echo "done. open a new terminal (or run: exec zsh) to pick up shell changes."

#!/usr/bin/env bash
# install.sh - set up a Mac from this repo: Homebrew, then dott, then dott --init.
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jgorodetsky/dotfiles/main/install.sh)"
# or, in a clone: ./install.sh
# dott does the rest (https://github.com/jgorodetsky/dott): it shows what each item would change
# and asks first. this script never runs sudo; Homebrew's own installer asks for your password once.
set -euo pipefail

brew_env(){ for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && { eval "$("$b" shellenv)"; return 0; }; done; return 1; }
command -v brew >/dev/null 2>&1 || brew_env || true
if ! command -v brew >/dev/null 2>&1; then
  echo "installing Homebrew (it asks for your Mac password once)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew_env
fi

# Homebrew 6+ loads a formula from another tap only once it is trusted: this tap's one formula
brew trust --formula jgorodetsky/dott/dott >/dev/null 2>&1 || true
brew list --formula dott >/dev/null 2>&1 || brew install jgorodetsky/dott/dott

here="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd || true)"
if [ -n "$here" ] && [ -f "$here/dott.toml" ]; then exec dott --init "$here"; fi
exec dott --init jgorodetsky/dotfiles

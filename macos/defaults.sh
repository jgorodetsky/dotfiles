#!/usr/bin/env bash
# minimal, uncontroversial macos defaults. opt-in — run it yourself or from bootstrap.
set -euo pipefail

# faster key repeat
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 2

# show all file extensions in finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# save screenshots to ~/Screenshots instead of the desktop
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location "$HOME/Screenshots"

echo "macos defaults applied. some changes need a logout or a Finder/SystemUIServer restart."

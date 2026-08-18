#!/usr/bin/env bash
# minimal, uncontroversial macos defaults. opt-in — run it yourself or via install.sh.
set -euo pipefail

# faster key repeat (needs a re-login to take effect)
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 2

# show all file extensions in finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# save screenshots to ~/Screenshots instead of the desktop
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location "$HOME/Screenshots"

# reload the services that read these so changes apply now (|| true: never abort the run)
killall Finder >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true

echo "macos defaults applied (Finder + SystemUIServer reloaded). key repeat takes effect after re-login."

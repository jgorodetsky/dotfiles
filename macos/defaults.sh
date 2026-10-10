#!/usr/bin/env bash
# minimal, uncontroversial macos defaults. opt-in — run it yourself or via install.sh.
set -euo pipefail

# first run only: save the values this script changes, so they can be restored by hand
BAK="$HOME/.dotfiles-macos-defaults.bak"
if [ ! -f "$BAK" ]; then
  for k in "-g InitialKeyRepeat" "-g KeyRepeat" "NSGlobalDomain AppleShowAllExtensions" "com.apple.screencapture location"; do
    printf '%s = %s\n' "$k" "$(defaults read $k 2>/dev/null || echo unset)"
  done > "$BAK"
  echo "previous values saved to $BAK"
fi
# the keyboard shortcuts were added later; save their old values too on machines with an older backup
for h in 160 240 241; do
  grep -q "^hotkey $h " "$BAK" || printf 'hotkey %s = %s\n' "$h" \
    "$(defaults export com.apple.symbolichotkeys - 2>/dev/null | plutil -extract AppleSymbolicHotKeys.$h json -o - - 2>/dev/null || echo unset)" >> "$BAK"
done

# faster key repeat (needs a re-login to take effect)
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 2

# show all file extensions in finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# save screenshots to ~/Screenshots instead of the desktop
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location "$HOME/Screenshots"

# cmd+1 opens the apps launcher (system settings > keyboard > keyboard shortcuts >
# launchpad & dock). 49 = "1", 18 = the 1 key, 1048576 = command. takes over cmd+1 in every app.
# xml form so the values are stored as real booleans/integers, like system settings writes them
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 160 \
  '<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>49</integer><integer>18</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'

# tile window to the left / right half with control+option+arrow instead of fn+control+arrow
# (window > move & resize). 123/124 = left/right arrow, 9175040 = control + option + arrow-key flag
for pair in 240:123 241:124; do id="${pair%:*}"; key="${pair#*:}"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$id" \
    "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>$key</integer><integer>9175040</integer></array><key>type</key><string>standard</string></dict></dict>"
done
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u >/dev/null 2>&1 || true

# reload the services that read these so changes apply now (|| true: never abort the run)
killall Finder >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true

echo "macos defaults applied (Finder + SystemUIServer reloaded). key repeat takes effect after re-login."

# interactive-shell config. loaded on every terminal.

# completions — brew puts its completion dirs on fpath (in .zprofile); load them
autoload -Uz compinit && compinit

# ghh — sourced so it loads as a shell function (+ completions)
command -v ghh >/dev/null && source "$(command -v ghh)"

# gtheme — ghostty theme picker (installed to ~/.config/ghostty/gtheme)
[ -f "$HOME/.config/ghostty/gtheme" ] && alias gtheme="$HOME/.config/ghostty/gtheme"

# git shortcuts
alias gst='git status'
alias gpush='git push'
alias p='python3'

# DESTRUCTIVE: checks out main and hard-resets it to origin, discarding ALL local
# commits and uncommitted work on main. named resetmain (not fetch) on purpose.
alias resetmain='git checkout main && git fetch origin && git reset --hard origin/main'

# gpg: which terminal to prompt on for commit signing
export GPG_TTY=$(tty)

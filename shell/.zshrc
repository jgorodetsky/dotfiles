# interactive-shell config. loaded on every terminal.

# ghh — sourced so it loads as a shell function (+ completions)
command -v ghh >/dev/null && source "$(command -v ghh)"

# git shortcuts
alias fetch='git checkout main && git fetch origin && git reset --hard origin/main'
alias gst='git status'
alias gpush='git push'
alias p='python3'

# gpg: which terminal to prompt on for commit signing
export GPG_TTY=$(tty)

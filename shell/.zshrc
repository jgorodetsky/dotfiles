# interactive-shell config. loaded on every terminal.
# machine-specific stuff (work aliases, secrets wiring) goes in ~/.zshrc.local,
# which loads near the end so it wins over anything defined here.

DOTFILES_SHELL="${${(%):-%x}:A:h}"

# completions - brew puts its completion dirs on fpath (in .zprofile); load them
autoload -Uz compinit && compinit
autoload -Uz bashcompinit && bashcompinit

# aws cli ships a bash-style completer
command -v aws_completer >/dev/null && complete -C aws_completer aws

# ghh - sourced so it loads as a shell function (+ completions)
command -v ghh >/dev/null && source "$(command -v ghh)"

# gtheme - ghostty theme picker (installed to ~/.config/ghostty/gtheme)
[ -f "$HOME/.config/ghostty/gtheme" ] && alias gtheme="$HOME/.config/ghostty/gtheme"

# git shortcuts
alias gst='git status'
alias gpush='git push'
alias gaa='git add .'
alias gcm='git commit -m'
alias gpf='git push --force-with-lease --force-if-includes'
alias gd='git diff'
alias gds='git diff --staged'
alias gdw='git diff --word-diff'
alias gdh='git diff HEAD'
alias gsh='git show'
alias glp='git log -p'
alias gap='git add -p'
alias gbl='git blame'
# an s in front of a diff alias shows it side by side: sgd, sgds, sgdm, sgsh, sglp.
# git add -p needs the plain layout and blame isn't a diff, so gap and gbl have none
alias sgd='DELTA_FEATURES=+side-by-side git diff'
alias sgds='DELTA_FEATURES=+side-by-side git diff --staged'
alias sgdm='DELTA_FEATURES=+side-by-side gdm'
alias sgsh='DELTA_FEATURES=+side-by-side git show'
alias sglp='DELTA_FEATURES=+side-by-side git log -p'
alias p3='python3'
alias pwdc='pwd | pbcopy'

# gdm - everything this branch changed vs main (or master), what the PR will show
gdm() {
  local base b
  base=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
  for b in origin/main origin/master main master; do
    [[ -n $base ]] && break
    git rev-parse -q --verify "$b" >/dev/null && base=$b
  done
  git diff "${base:-main}...HEAD" "$@"
}

# lazygit: the repo's lazygit/config.yml (diffs drawn by delta), then your own config.yml if you
# have one, which wins. neovim's space g g reads the same list
if command -v lazygit >/dev/null; then
  alias lg='lazygit'
  _lg_own="${XDG_CONFIG_HOME:-$HOME/.config}/lazygit/config.yml"
  [[ $OSTYPE == darwin* && -z ${XDG_CONFIG_HOME:-} ]] && _lg_own="$HOME/Library/Application Support/lazygit/config.yml"
  export LG_CONFIG_FILE="${DOTFILES_SHELL:h}/lazygit/config.yml"
  [[ -f $_lg_own ]] && LG_CONFIG_FILE+=",$_lg_own"
  unset _lg_own
fi

# DESTRUCTIVE: checks out main and hard-resets it to origin, discarding ALL local
# commits and uncommitted work on main. named resetmain (not fetch) on purpose.
alias resetmain='git checkout main && git fetch origin && git reset --hard origin/main'

# eza/bat when installed, plain ls/cat otherwise
if command -v eza >/dev/null; then
  alias ls='eza -1 --group-directories-first'
  alias ll='eza -l --git --group-directories-first'
  alias la='eza -la --git --group-directories-first'
else
  alias ls='ls -1'
fi
command -v bat >/dev/null && alias cat='bat --paging=never --style=plain'

# neovim (lazyvim config in nvim/), nv for short. it's $EDITOR when installed, plain vim otherwise.
# an editor you set yourself (code, nano...) is kept; a leftover plain vim gets upgraded
if [[ -z ${EDITOR:-} || $EDITOR == vim ]]; then
  command -v nvim >/dev/null && export EDITOR=nvim || export EDITOR=vim
fi
command -v nvim >/dev/null && alias nv='nvim'

# gpg: which terminal to prompt on for commit signing
export GPG_TTY=$(tty)

# claude code: native installs auto-update on their own; this makes brew installs do it too
export CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE=1

# ccupdate - update claude code now, however it was installed
ccupdate() {
  local cask
  if [[ "$(command -v claude)" == "${HOMEBREW_PREFIX:-/opt/homebrew}"/* ]] &&
     cask=$(brew list --cask 2>/dev/null | grep -m1 '^claude-code'); then
    brew upgrade --cask "$cask"
  else
    claude update
  fi
}

# power - charger watts vs what the mac uses, then press e for the top energy users (power 25 lists more)
power() {
  local io ad conn name watts in load amp volt bat pct stale=0 key rows pid cpu imp
  io=$(ioreg -rw0 -c AppleSmartBattery)
  # read the charger's own section: other sections (like power sent out to a usb device) also have Watts
  ad=$(print -r -- "$io" | grep '^ *"AdapterDetails" = ')
  name=$(print -r -- "$ad" | grep -o '"Name"="[^"]*"' | head -1 | cut -d'"' -f4)
  watts=$(print -r -- "$ad" | grep -o '"Watts"=[0-9]*' | head -1 | cut -d= -f2)
  conn=$(print -r -- "$io" | awk -F' = ' '/^ *"ExternalConnected" = /{print $2}')
  in=$(print -r -- "$io" | grep -o '"SystemPowerIn"=[0-9]*' | cut -d= -f2)
  load=$(print -r -- "$io" | grep -o '"SystemLoad"=[0-9]*' | cut -d= -f2)
  amp=$(print -r -- "$io" | awk -F' = ' '/"Amperage" = /{print $2}')
  volt=$(print -r -- "$io" | awk -F' = ' '/"Voltage" = /{print $2}')
  # ioreg prints negative amps as unsigned 64-bit
  (( ${#amp} > 10 )) && amp=-$(bc <<< "18446744073709551616 - $amp")
  bat=$(( ${amp:-0} * ${volt:-0} / 1e6 ))
  pct=$(pmset -g batt | grep -o '[0-9]*%')
  # the connected flag changes at once, the power readings up to a minute later
  if [[ $conn == Yes ]]; then
    printf 'charger:        %s\n' "${name:-unknown}"
    printf 'charger agreed: %sW\n' "${watts:-0}"
    printf 'charger giving: %.1fW\n' $(( ${in:-0} / 1000.0 ))
    (( ${in:-0} > 0 )) || stale=1
  else
    print 'charger:        not connected'
    (( bat <= 0 )) || stale=1
  fi
  printf 'mac using:      %.1fW\n' $(( ${load:-0} / 1000.0 ))
  printf 'battery:        %+.1fW at %s (+ charging, - draining)\n' $bat "$pct"
  (( stale )) && print 'readings still catching up after the charger change - run power again in a minute'
  # in a terminal, wait for a key; piped, print everything
  if [[ -t 0 && -t 1 ]]; then
    print -r -- $'\n'${(l:40::─:)}
    print -n 'e  show the top energy users    q  quit '
    read -sk1 key
    print -n '\r\e[K'
    [[ $key == [eE] ]] || return 0
    print -n 'measuring for 2 seconds...'
  fi
  # top's first sample has no cpu history, so read the second one; skip pids that exited since
  rows=$(top -l 2 -s 2 -o power -n ${1:-15} -stats pid,cpu,power | awk '/^PID/{n++; next} n == 2 && NF == 3' |
    while read -r pid cpu imp; do
      ps -p $pid >/dev/null 2>&1 || continue
      print -r -- "$pid"$'\t'"$(ps -o comm= -p $pid | sed 's|.*/||')"$'\t'"$cpu"$'\t'"$imp"$'\t'"$(_proc_what $pid)"$'\t'"$(_proc_age $pid)"
    done)
  [[ -t 1 ]] && print -n '\r\e[K'
  print
  { print -r -- $'pid\tname\tcpu %\timpact\twhat it is / where it lives\trunning for'; print -r -- "$rows"; } |
    if (( $+commands[boxtable] )); then boxtable --plain --no-sort; else column -t -s $'\t'; fi
  print 'cpu % = share of one core (100 = one core flat out). impact = energy score, not watts.'
  print 'pinfo <pid> - what it is, who started it, how to look deeper or stop it'
}

# what a process is: the script an interpreter runs, the app it belongs to, or its command line
_proc_what() {
  local exe args
  exe=$(ps -o comm= -p $1 2>/dev/null) || return
  args=$(ps -o args= -p $1 2>/dev/null)
  if [[ ${exe:t} == (Python|python*|node|ruby|perl|bash|sh|zsh|bun|deno|java) ]]; then
    print -r -- "${exe:t} script: ${${args#* }//$HOME/~}"
  elif [[ $exe == /System/*.app/* ]]; then
    print -r -- "part of macOS: ${${exe%%.app/*}:t}.app"
  elif [[ $exe == *.app/* ]]; then
    print -r -- "part of ${${exe%%.app/*}//$HOME/~}.app"
  elif [[ $exe == (/System|/usr/libexec|/usr/sbin|/sbin)/* ]]; then
    print -r -- "part of macOS: ${exe:t}${args#$exe}"
  else
    print -r -- "${args//$HOME/~}"
  fi
}

# how long a process has run, from ps etime ([dd-]hh:mm:ss) to "3d 4h", "5h 12m" or "7m"
_proc_age() {
  ps -o etime= -p $1 2>/dev/null | awk '{
    d = 0; t = $1; if (t ~ /-/) { split(t, a, "-"); d = a[1]; t = a[2] }
    n = split(t, b, ":"); h = (n == 3) ? b[1] : 0; m = (n == 3) ? b[2] : b[1]
    if (d > 0) printf "%dd %dh\n", d, h; else if (h > 0) printf "%dh %dm\n", h, m; else printf "%dm\n", m }'
}

# pinfo - what a process is, who started it, and the commands to look deeper or stop it
pinfo() {
  local pid=${1:?usage: pinfo <pid>} exe args cwd p chain label plist copies macos=0
  ps -p $pid >/dev/null 2>&1 || { print -r -- "no process $pid"; return 1; }
  exe=$(ps -o comm= -p $pid); args=$(ps -o args= -p $pid)
  # comm is only a name when the program was started by name, so ask for its file
  [[ $exe == /* ]] || exe=$(lsof -a -p $pid -d txt -Fn 2>/dev/null | sed -n 's/^n//p' | head -1)
  cwd=$(lsof -a -p $pid -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')
  p=$pid
  while p=$(ps -o ppid= -p $p 2>/dev/null | tr -d ' ') && (( p > 1 )); do
    chain+="${chain:+ <- }$(ps -o comm= -p $p | sed 's|.*/||') ($p)"
  done
  label=$(launchctl list 2>/dev/null | awk -v p=$pid '$1 == p {print $3}')
  [[ -n $label ]] && plist=$(launchctl print gui/$UID/$label 2>/dev/null | awk -F' = ' '$1 ~ /^\tpath$/ {print $2; exit}')
  [[ $pid == 1 || $label == com.apple.* || $exe == (/System|/usr/libexec|/usr/sbin|/sbin)/* ]] && macos=1
  copies=$(ps -axo args= | grep -cxF -- "$args")
  print -r -- "what:       $(_proc_what $pid)"
  print -r -- "program:    ${exe//$HOME/~}"
  print -r -- "command:    ${args//$HOME/~}"
  print -r -- "folder:     ${${cwd:-unknown}//$HOME/~}"
  print -r -- "started:    $(ps -o lstart= -p $pid | sed 's/ *$//') ($(_proc_age $pid) ago)"
  print -r -- "now:        $(ps -o %cpu= -p $pid | tr -d ' ')% cpu, $(( $(ps -o rss= -p $pid) / 1024 )) MB memory, $(lsof -a -i -p $pid 2>/dev/null | tail -n +2 | wc -l | tr -d ' ') network connections"
  if [[ -n $label ]]; then
    print -r -- "started by: launchd job $label - it starts again if you only kill it"
    [[ -n $plist ]] && print -r -- "job file:   ${plist//$HOME/~}"
  elif (( macos )); then
    print -r -- "started by: macOS"
  elif [[ -n $chain ]]; then
    print -r -- "started by: $chain"
  elif [[ $exe == *.app/* ]]; then
    print -r -- "started by: you opened the app"
  else
    print -r -- "started by: nothing now - whatever started it has exited (an orphan)"
  fi
  (( copies > 1 )) && print -r -- "copies:     $copies running with this exact command"
  print
  print -r -- "look deeper"
  print -r -- "  sample $pid 3          the code it is running right now, for 3 seconds"
  print -r -- "  lsof -p $pid           every file and network connection it has open"
  print -r -- "stop it"
  if (( macos )); then
    print -r -- "  leave it - it is part of macOS"
  elif [[ -n $label ]]; then
    print -r -- "  launchctl bootout gui/$UID/$label    stops it until your next login"
    [[ $plist == $HOME/* ]] && print -r -- "  then move ${plist//$HOME/~} out of that folder to stop it for good"
  elif [[ -z $chain && $exe == *.app/* ]]; then
    print -r -- "  quit ${${exe%%.app/*}:t} the normal way (cmd+q)"
  else
    print -r -- "  kill $pid              asks it to quit (try this first)"
    print -r -- "  kill -9 $pid           forces it, if it ignores that"
    (( copies > 1 )) && print -r -- "  pkill -fx '${args}'   stops every copy with this exact command"
  fi
}

# fzf: ctrl-r history search, ctrl-t file picker with a bat preview,
# alt-c (or esc then c) cd into a folder with a tree preview
_fzf_file_preview='bat --style=numbers --color=always --line-range :500 {}'
command -v bat >/dev/null || _fzf_file_preview='head -500 {}'
_fzf_dir_preview='eza --tree --level=2 --color=always --group-directories-first'
command -v eza >/dev/null || _fzf_dir_preview='ls -Cp'
export FZF_CTRL_T_OPTS="--preview '$_fzf_file_preview'"
export FZF_ALT_C_OPTS="--preview '$_fzf_dir_preview {}'"
command -v fzf >/dev/null && source <(fzf --zsh)

# open file $1 at line $2 in $EDITOR
_open_at() {
  if [[ $EDITOR == code* ]]; then code -g "$1:${2:-1}"
  else ${=EDITOR} +"${2:-1}" "$1"; fi
}

# ff - fuzzy-pick a file with a bat preview, enter opens it in $EDITOR
ff() {
  local f
  f=$(fzf --preview "$_fzf_file_preview" --query="${*:-}") || return
  _open_at "$f"
}

# fif - live search inside files as you type, enter opens the match in $EDITOR
fif() {
  local rg='rg --column --line-number --no-heading --color=always --smart-case'
  local hit
  hit=$(fzf --ansi --disabled --query "${*:-}" \
      --bind "start:reload:$rg {q} || true" \
      --bind "change:reload:sleep 0.1; $rg {q} || true" \
      --delimiter : \
      --preview 'bat --color=always --style=numbers --highlight-line {2} {1}' \
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3') || return
  local file=${hit%%:*} rest=${hit#*:}
  _open_at "$file" "${rest%%:*}"
}

# zoxide: z <part-of-path> jumps there, zi picks from your frequent dirs with fzf.
# these are zoxide's own fzf defaults with the tree preview swapped in ({2..} is the path)
export _ZO_FZF_OPTS="--exact --no-sort --cycle --keep-right --height=45% --layout=reverse --info=inline \
--tabstop=1 --exit-0 --bind=ctrl-z:ignore,btab:up,tab:down --preview='$_fzf_dir_preview {2..}' --preview-window=down,40%"
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# awslogin - fzf-pick an aws profile for this shell, sso login only if the session expired
awslogin() {
  local profile="${1:-}"
  if [[ -z $profile ]]; then
    profile=$(aws configure list-profiles | fzf --height=15 --prompt="aws profile: ") || return 1
  fi
  aws sts get-caller-identity --profile "$profile" >/dev/null 2>&1 ||
    aws sso login --profile "$profile" || return 1
  export AWS_PROFILE="$profile"
  echo "AWS_PROFILE=$AWS_PROFILE"
}

# what you're actually authenticated as
alias awsme='aws sts get-caller-identity'

# kubernetes
alias k='kubectl'
alias kcur='kubectl config current-context'

# kctx - fzf-pick the kube context; kctx -u clears it (kubectl then points nowhere)
kctx() {
  if [[ ${1:-} == (-u|--unset) ]]; then kubectl config unset current-context; return; fi
  local ctx
  ctx=$(kubectl config get-contexts -o name | fzf --height=10 --prompt="kube context: ") || return 1
  kubectl config use-context "$ctx"
}

# alias - with no arguments on screen, list aliases as a table; anything else is the normal builtin
alias() {
  if (( $# == 0 )) && [[ -t 1 ]] && (( $+commands[boxtable] )); then
    local k
    { print -r -- $'alias\truns'
      for k in ${(ok)aliases}; do print -r -- "$k"$'\t'"${aliases[$k]//$'\t'/ }"; done
    } | boxtable
  else
    builtin alias "$@"
  fi
}

# mine - everything on your setup in one a-z table: tools, keys, aliases and functions. mine aws to filter.
# aliases and functions are read live from .zshrc / .zshrc.local; tools and keys live in shell/mine.tsv.
# a function's description is its own "# name - ..." comment line, so keep that line self-contained.
mine() {
  local f k desc
  [[ ${1:-} == (-e|--edit|-h|--help) ]] && { mine-table "$@"; return; }
  { for k in ${(ok)aliases}; do
      [[ $k == (run-help|which-command) ]] && continue   # zsh defaults, not yours
      print -r -- "$k"$'\t'"alias"$'\t'"${aliases[$k]//$'\t'/ }"; done
    for f in ${(ko)functions}; do
      [[ $f == _* || ${functions_source[$f]} != *.zshrc(|.local) ]] && continue
      grep -q "^${f}() {" "${functions_source[$f]}" || continue   # skip ones created by eval (starship, zoxide)
      desc=$(sed -n "s/^# ${f} - //p" "${functions_source[$f]}" | head -1)
      print -r -- "$f"$'\t'"function"$'\t'"$desc"
    done
  } | mine-table "$@"
}

# starship prompt: folder, git, aws profile, kube context. skipped if another
# prompt (oh-my-zsh theme, powerlevel10k) is already set up on this machine
if command -v starship >/dev/null && [[ -z ${ZSH_THEME:-} ]] && (( ! $+functions[p10k] )); then
  [[ -z ${STARSHIP_CONFIG:-} && ! -f "$HOME/.config/starship.toml" ]] &&
    export STARSHIP_CONFIG="$DOTFILES_SHELL/starship.toml"
  eval "$(starship init zsh)"
fi

# typing helpers, unless something already loaded them
_bp="${HOMEBREW_PREFIX:-/opt/homebrew}/share"
(( $+functions[_zsh_autosuggest_start] )) ||
  { [ -f "$_bp/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "$_bp/zsh-autosuggestions/zsh-autosuggestions.zsh"; }

# ghostty tabs: "<status> <icon> <name>" titles by rule, tn to rename (does nothing outside ghostty)
[ -f "$DOTFILES_SHELL/tabs.zsh" ] && source "$DOTFILES_SHELL/tabs.zsh"

# aliases added with dott
alias cl='clear'

# machine-specific config, loaded after everything above so it wins
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# syntax highlighting has to load last
(( $+functions[_zsh_highlight] )) ||
  { [ -f "$_bp/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "$_bp/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; }
unset _bp

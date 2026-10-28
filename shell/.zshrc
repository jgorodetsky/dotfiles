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

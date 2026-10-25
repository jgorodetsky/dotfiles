# ghostty tab titles by rule: "<status> <icon> <name>", so tabs can be told apart at a glance.
#   🟢 at the prompt   🟡 something running   🔵 an agent (claude, codex, ...) and its folder   🔴 ssh, or a prod aws/kube context
# tn <name> renames a tab and it keeps showing what runs in it: "🟡 🐍 api · python3".
# in a prod context the whole tab also gets a blue tint. ghostty only; pairs with ghostty/tabs.conf.
[[ $TERM_PROGRAM == ghostty ]] || return 0

# claude code sets its own tab title; turn that off so the tab keeps these
export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1

# an aws profile or kube context matching this pattern counts as prod
: ${TABS_PROD_PATTERN:='*prod*'}
# background color for prod tabs; set TABS_PROD_TINT= (empty) to turn the tint off
: ${TABS_PROD_TINT='#12263f'}

# program -> emoji. anything not listed gets the gear
typeset -gA _tab_icons
_tab_icon() { local icon=$1 n; shift; for n; do _tab_icons[$n]=$icon; done }
_tab_icon '⚙️'  default
_tab_icon '📁'  folder
_tab_icon '🌿'  gitfolder git ghh lazygit tig
_tab_icon '🏠'  home
_tab_icon '📝'  nvim vim vi nano
_tab_icon '🐙'  gh
_tab_icon '🤖'  claude codex opencode pi
_tab_icon '🐍'  python python3 ipython pip pip3 uv ruff
_tab_icon '🐹'  go
_tab_icon '📦'  node npm npx bun deno
_tab_icon '🐳'  docker
_tab_icon '☸️'  kubectl k9s minikube kubeseal kctx kcur helm
_tab_icon '🏗️'  terraform
_tab_icon '☁️'  aws awslogin awssetup az
_tab_icon '🔐'  ssh scp mosh
_tab_icon '🍺'  brew
_tab_icon '📖'  man tldr less bat
_tab_icon '🔍'  fzf ff fif rg grep find
_tab_icon '📊'  mine boxtable trials top htop btop
_tab_icon '🌐'  curl wget
_tab_icon '🔨'  make
_tab_icon '🗄️'  sqlite3 psql mysql
_tab_icon '🛡️'  trivy syft hadolint grype gitleaks semgrep
_tab_icon '🎬'  yt-dlp
unfunction _tab_icon

typeset -g _tab_name _tab_in_prod=0 _tab_tinted=0

_tab_title() { print -rn -- $'\e]2;'"$1"$'\a' }

# prod if the aws profile or the kube context matches TABS_PROD_PATTERN. reads the kubeconfig
# directly because running kubectl on every prompt is too slow
_tab_prod() {
  [[ -n $AWS_PROFILE && $AWS_PROFILE == ${~TABS_PROD_PATTERN} ]] && return 0
  local cfg=${KUBECONFIG%%:*} line ctx
  cfg=${cfg:-$HOME/.kube/config}
  [[ -r $cfg ]] || return 1
  while IFS= read -r line; do
    [[ $line == current-context:* ]] && { ctx=${${line#current-context:}//[\"\' ]/}; break; }
  done < $cfg
  [[ -n $ctx && $ctx == ${~TABS_PROD_PATTERN} ]]
}

# tint the tab while in prod, put the normal background back when leaving it
_tab_tint() {
  if (( _tab_in_prod )) && [[ -n $TABS_PROD_TINT ]]; then
    print -rn -- $'\e]11;'"$TABS_PROD_TINT"$'\a'; _tab_tinted=1
  elif (( _tab_tinted )); then
    print -rn -- $'\e]111\a'; _tab_tinted=0
  fi
}

# at the prompt: folder icon and name (git folder, house at ~), or the tn name
_tab_precmd() {
  _tab_prod && _tab_in_prod=1 || _tab_in_prod=0
  _tab_tint
  local dot icon=$_tab_icons[folder] name=${PWD:t} d=$PWD
  while [[ -n $d ]]; do [[ -e $d/.git ]] && { icon=$_tab_icons[gitfolder]; break; }; d=${d%/*}; done
  [[ $PWD == / ]] && name=/
  [[ $PWD == $HOME ]] && { icon=$_tab_icons[home]; name='~'; }
  [[ -n $_tab_name ]] && name=$_tab_name
  (( _tab_in_prod )) && dot=🔴 || dot=🟢
  _tab_title "$dot $icon $name"
}

# while a command runs: its icon and name. skips env assignments and wrappers like sudo,
# looks through aliases (k shows as kubectl), and shows the host for ssh
_tab_preexec() {
  local -a words=(${(z)1}) expanded; local w i dot name
  for (( i = 1; i <= $#words; i++ )); do
    w=$words[i]
    [[ $w == *=* || $w == (sudo|command|builtin|exec|nocorrect|noglob|time|env|nohup|caffeinate) ]] || break
  done
  (( $+aliases[$w] )) && { expanded=(${(z)aliases[$w]}); w=$expanded[1]; }
  w=${${(Q)w}:t}
  name=$w
  if [[ $w == (ssh|mosh) ]]; then
    local a skip=0
    for a in ${words[i+1,-1]}; do
      (( skip )) && { skip=0; continue; }
      [[ $a == -[ioplFJ] ]] && { skip=1; continue; }
      [[ $a == -* ]] && continue
      name="$w · ${a#*@}"; break
    done
  fi
  [[ -n $_tab_name ]] && name="$_tab_name · $name"
  # agents often run several at once, so their tabs show the folder (or tn name) instead
  case $w in
    claude|codex|opencode|pi) dot=🔵 name="${_tab_name:-${${PWD/#$HOME/~}:t}}" ;;
    ssh|mosh)                 dot=🔴 ;;
    *) (( _tab_in_prod )) && dot=🔴 || dot=🟡 ;;
  esac
  _tab_title "$dot ${_tab_icons[$w]:-$_tab_icons[default]} $name"
}

# tn - name this tab; it keeps showing what runs in it ("api · nvim"). plain tn goes back to automatic
tn() { _tab_name="$*"; _tab_precmd }

autoload -Uz add-zsh-hook
add-zsh-hook precmd _tab_precmd
add-zsh-hook preexec _tab_preexec

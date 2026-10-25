#!/usr/bin/env bash
# dotfiles installer + health check. safe to re-run over an existing setup: it detects
# what's already installed (green check + where) and only offers to add the diff.
# it never replaces your files: shell and git get a source/include line appended,
# anything it would change gets a timestamped .bak first.
#
#   ./install.sh                 health-check, then fuzzy-pick what to install from the diff
#   ./install.sh --all           install everything missing (no prompt)
#   ./install.sh --check         health-check only (report; installs nothing)
#   ./install.sh --only a,b      (re)apply just these ids, e.g. --only shell,skills
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=pick; ONLY=""
case "${1:-}" in
  --all) MODE=all ;; --check) MODE=check ;; ""|--pick) MODE=pick ;;
  --only) MODE=only; ONLY=",${2:?usage: install.sh --only id[,id...]},"; ;;
  *) echo "usage: install.sh [--all|--check|--only id,...]" >&2; exit 2 ;;
esac
STAMP="$(date +%Y%m%d%H%M%S)"
MARK_START="# >>> dotfiles >>>"; MARK_END="# <<< dotfiles <<<"
TABS_START="# >>> dotfiles tabs >>>"; TABS_END="# <<< dotfiles tabs <<<"

# ghostty's config: the macos app support file if it exists, else xdg (same order as ghostty/install.sh)
GHOSTTY_CONFIG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
[ -f "$GHOSTTY_CONFIG" ] || GHOSTTY_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"

# put_block FILE START END BODY - our marked block in FILE. appended if missing; if it's there but
# different (say it points at another checkout of this repo) it's rewritten, with a .bak of the file first
put_block(){
  local f="$1" s="$2" e="$3" b="$4" new
  touch "$f"
  if ! grep -qsF "$s" "$f"; then
    printf '\n%s\n%s\n%s\n' "$s" "$b" "$e" >> "$f"; echo "  $f: appended the block, your existing lines are untouched"; return
  fi
  new="$(awk -v s="$s" -v e="$e" -v b="$b" '$0 == s { print; print b; skip = 1; next } $0 == e { skip = 0 } !skip' "$f")"
  if [ "$new" = "$(cat "$f")" ]; then echo "  $f: block already up to date"; return; fi
  cp "$f" "$f.bak-$STAMP"; printf '%s\n' "$new" > "$f"
  echo "  $f: block now points at $DIR (old file kept as $f.bak-$STAMP)"
}

if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; D=$'\033[2m'; B=$'\033[1m'; X=$'\033[0m'
else G= R= Y= D= B= X=; fi

# ---------- prereqs: xcode CLT + homebrew (needed before we can check anything) ----------
xcode-select -p >/dev/null 2>&1 || xcode-select --install 2>/dev/null || true
if ! command -v brew >/dev/null 2>&1; then
  echo "installing homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [ -x "$b" ] && { eval "$("$b" shellenv)"; break; }
done

# ---------- manifest: packages parsed from Brewfile + config features ----------
IDS=(); CLASSES=(); DESCS=(); KINDS=(); TARGETS=(); SPECS=()
cls=misc
while IFS= read -r line || [ -n "$line" ]; do
  if [[ "$line" =~ ^#[[:space:]]+([a-z][a-z-]*)[[:space:]]*$ ]]; then
    cls="${BASH_REMATCH[1]}"
  elif [[ "$line" =~ ^(brew|cask)[[:space:]]+\"([^\"]+)\"(.*#[[:space:]](.*))?$ ]]; then
    k="${BASH_REMATCH[1]}"; full="${BASH_REMATCH[2]}"; dsc="${BASH_REMATCH[4]:-}"
    IDS+=("${full##*/}"); CLASSES+=("$cls"); DESCS+=("${dsc:-${full##*/}}")
    [ "$k" = cask ] && KINDS+=(cask) || KINDS+=(formula); TARGETS+=("$full")
    spec="${line%%#*}"; SPECS+=("${spec%"${spec##*[![:space:]]}"}")   # the Brewfile line minus its comment
  fi
done < "$DIR/Brewfile"

add_cfg(){ IDS+=("$1"); CLASSES+=(config); DESCS+=("$2"); KINDS+=(config); TARGETS+=("$1"); SPECS+=(""); }
add_cfg shell   "append a source line to ~/.zprofile + ~/.zshrc"
add_cfg git     "include repo git config in ~/.gitconfig"
add_cfg ghostty-theme "ChessKing + cadillac themes + gtheme picker"
add_cfg ghostty-tabs "tab titles by rule: status dot, emoji, name (shell/tabs.zsh + ghostty/tabs.conf)"
add_cfg nvim    "neovim config (lazyvim): link ~/.config/nvim to nvim/"
add_cfg skills  "agent skills -> ~/.agents/skills + ~/.claude/skills"
add_cfg macos   "key repeat, file extensions, screenshots, cmd+1 apps, ctrl+opt+arrow tiling"
add_cfg claude  "claude code, native install (auto-updates itself)"
add_cfg aws     "aws sso: one login, a profile for every account you can reach (awssetup)"

# homebrew 6+ refuses third-party formulae until they're trusted. trust every Brewfile
# entry marked trusted: true on every run, so taps like hashicorp/tap never need a manual step.
if [ "$MODE" != check ] && brew trust --help >/dev/null 2>&1; then
  while IFS= read -r line; do
    [[ "$line" =~ ^(brew|cask|tap)[[:space:]]+\"([^\"]+)\".*trusted:[[:space:]]*true ]] || continue
    case "${BASH_REMATCH[1]}" in brew) t=--formula ;; cask) t=--cask ;; tap) t=--tap ;; esac
    brew trust "$t" "${BASH_REMATCH[2]}" >/dev/null 2>&1 || printf '%swarning: could not trust %s%s\n' "$Y" "${BASH_REMATCH[2]}" "$X"
  done < "$DIR/Brewfile"
fi

# ---------- detection ----------
FORMULAE="$(brew list --formula -1 2>/dev/null || true)"
CASKS="$(brew list --cask -1 2>/dev/null || true)"
WHERE=""
detect(){ # $1 index -> 0 installed (sets WHERE) / 1 missing
  local id="${IDS[$1]}" kind="${KINDS[$1]}" p v; WHERE=""
  case "$kind" in
    formula)
      printf '%s\n' "$FORMULAE" | grep -qxE "($id|.*/$id)" || return 1
      p="$(command -v "$id" 2>/dev/null || true)"
      v="$(brew list --versions "$id" 2>/dev/null | awk '{print $2}')"
      WHERE="${p:-$(brew --prefix "$id" 2>/dev/null || echo "$id")}${v:+  ($v)}" ;;
    cask)
      if printf '%s\n' "$CASKS" | grep -qx "$id"; then WHERE="brew cask: $id"
      elif [ "$id" = ghostty ] && [ -d /Applications/Ghostty.app ]; then WHERE="/Applications/Ghostty.app (non-brew)"
      elif [ "$id" = visual-studio-code ] && [ -d "/Applications/Visual Studio Code.app" ]; then WHERE="/Applications/Visual Studio Code.app (non-brew)"
      else return 1; fi ;;
    config)
      case "$id" in
        shell)   for f in .zprofile .zshrc; do grep -qsF "$DIR/shell/$f" "$HOME/$f" || return 1; done
                 WHERE="~/.zprofile + ~/.zshrc [dotfiles block]" ;;
        git)     grep -qsF "$DIR/git/.gitconfig" "$HOME/.gitconfig" && WHERE="$HOME/.gitconfig [include]" || return 1 ;;
        ghostty-tabs) grep -qsF "config-file = ?$DIR/ghostty/tabs.conf" "$GHOSTTY_CONFIG" || return 1
                      WHERE="$GHOSTTY_CONFIG [dotfiles tabs block]" ;;
        nvim)    [ "$(readlink "$HOME/.config/nvim" 2>/dev/null)" = "$DIR/nvim" ] || return 1
                 WHERE="~/.config/nvim -> $DIR/nvim" ;;
        ghostty-theme) for t in "$DIR"/ghostty/themes/*; do [ -f "$HOME/.config/ghostty/themes/${t##*/}" ] || return 1; done
                       WHERE="$HOME/.config/ghostty/themes ($(ls "$DIR/ghostty/themes" | wc -l | tr -d ' ') themes)" ;;
        skills)  for s in "$DIR"/agents/skills/*/; do for t in "$HOME/.agents/skills" "$HOME/.claude/skills"; do
                   diff -rq -x __pycache__ -x .dotfiles "$s" "$t/$(basename "$s")" >/dev/null 2>&1 || return 1; done; done
                 WHERE="~/.agents/skills + ~/.claude/skills ($(ls "$DIR/agents/skills" | wc -l | tr -d ' ') skills)" ;;
        macos)   [ "$(defaults read -g KeyRepeat 2>/dev/null || echo x)" = 2 ] || return 1
                 [ "$(defaults export com.apple.symbolichotkeys - 2>/dev/null | plutil -extract AppleSymbolicHotKeys.160.value.parameters json -o - - 2>/dev/null)" = "[49,18,1048576]" ] || return 1
                 [ "$(defaults export com.apple.symbolichotkeys - 2>/dev/null | plutil -extract AppleSymbolicHotKeys.240.value.parameters json -o - - 2>/dev/null)" = "[65535,123,9175040]" ] || return 1
                 WHERE="KeyRepeat=2, cmd+1 apps, ctrl+opt tiling (applied)" ;;
        claude)  p="$(command -v claude 2>/dev/null)" || return 1
                 case "$p" in "$(brew --prefix)"/*) WHERE="$p (homebrew; updated by brew via CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE)" ;;
                              *) WHERE="$p (native, auto-updates)" ;; esac ;;
        aws)     grep -qs '^\[sso-session ' "${AWS_CONFIG_FILE:-$HOME/.aws/config}" || return 1
                 WHERE="${AWS_CONFIG_FILE:-~/.aws/config} ($(grep -c '^\[profile ' "${AWS_CONFIG_FILE:-$HOME/.aws/config}") profiles)" ;;
      esac ;;
  esac
  return 0
}

# ---------- health check ----------
printf '\n%shealth check%s  %s%s%s\n\n' "$B" "$X" "$D" "$DIR" "$X"
MISSING=(); STATUS=()
for i in "${!IDS[@]}"; do
  if detect "$i"; then STATUS[$i]=ok; printf '  %s✓%s %-18s %s%s%s\n' "$G" "$X" "${IDS[$i]}" "$D" "$WHERE" "$X"
  else STATUS[$i]=miss; MISSING+=("$i"); printf '  %s✗%s %-18s %s%s%s\n' "$R" "$X" "${IDS[$i]}" "$D" "${DESCS[$i]}" "$X"; fi
done

if [ "${#MISSING[@]}" -eq 0 ]; then printf '\n%s✓ everything is installed.%s  %s(pick anything below to re-apply/update)%s\n' "$G" "$X" "$D" "$X"
else printf '\n%s%s missing:%s ' "$Y" "${#MISSING[@]}" "$X"; for i in "${MISSING[@]}"; do printf '%s ' "${IDS[$i]}"; done; printf '\n'; fi
[ "$MODE" = check ] && exit 0

# ---------- choose from the diff ----------
SEL=()
if [ "$MODE" = all ]; then
  [ "${#MISSING[@]}" -eq 0 ] && { printf '\n%snothing missing.%s\n' "$G" "$X"; exit 0; }
  SEL=("${MISSING[@]}")
elif [ "$MODE" = only ]; then
  for i in "${!IDS[@]}"; do [[ "$ONLY" == *",${IDS[$i]},"* ]] && SEL+=("$i"); done
else
  command -v fzf >/dev/null 2>&1 || brew install fzf >/dev/null
  if [ ! -t 0 ] || [ ! -t 1 ]; then
    printf '\nnot a terminal - re-run with %s--all%s to install everything missing.\n' "$B" "$X"; exit 0; fi
  chosen="$( { [ "${#MISSING[@]}" -gt 0 ] && printf 'MISSING\tinstall only what is missing, skip the rest (same as --all)\n'
      printf 'ALL\t(re)install everything, including what is already installed\n'
      for c in $(for i in "${!IDS[@]}"; do echo "${CLASSES[$i]}"; done | sort -u); do
        printf 'class:%s\t- whole %s class\n' "$c" "$c"; done
      for i in "${!IDS[@]}"; do
        [ "${STATUS[$i]}" = ok ] && m="[installed]" || m="[missing]"
        printf '%s\t%s %s - %s\n' "${IDS[$i]}" "$m" "${CLASSES[$i]}" "${DESCS[$i]}"; done
    } | fzf -m --delimiter='\t' --with-nth=1,2 --height=90% --layout=reverse --border \
        --prompt='(re)install > ' \
        --header='pick features (installed ones re-apply/update)   Tab=mark  Enter=go  Esc=cancel' \
      | cut -f1 )"
  [ -z "$chosen" ] && { echo "nothing selected."; exit 0; }
  wa=0; wm=0; wc=" "; wi=" "
  while IFS= read -r t; do case "$t" in
    ALL) wa=1 ;; MISSING) wm=1 ;; class:*) wc="$wc${t#class:} " ;; *) wi="$wi$t " ;; esac; done <<< "$chosen"
  for i in "${!IDS[@]}"; do
    if [ "$wa" = 1 ] || { [ "$wm" = 1 ] && [ "${STATUS[$i]}" != ok ]; } || [[ "$wc" == *" ${CLASSES[$i]} "* ]] || [[ "$wi" == *" ${IDS[$i]} "* ]]; then SEL+=("$i"); fi
  done
fi
[ "${#SEL[@]}" -eq 0 ] && { echo "nothing to install."; exit 0; }

# ---------- install selected ----------
pkg=(); cfg=()
for i in "${SEL[@]}"; do [ "${KINDS[$i]}" = config ] && cfg+=("$i") || pkg+=("$i"); done

if [ "${#pkg[@]}" -gt 0 ]; then
  tmp="$(mktemp)"; grep -E '^tap ' "$DIR/Brewfile" >> "$tmp" || true
  for i in "${pkg[@]}"; do   # copy the Brewfile line as-is so options like trusted: true survive
    if [ "${KINDS[$i]}" = cask ] && [[ "${SPECS[$i]}" != *args:* ]]; then
      printf '%s, args: { adopt: true }\n' "${SPECS[$i]}" >> "$tmp"
    else printf '%s\n' "${SPECS[$i]}" >> "$tmp"; fi
  done
  printf '\n%sinstalling packages...%s\n' "$B" "$X"; brew bundle --file="$tmp"; rm -f "$tmp"
fi

if [ "${#cfg[@]}" -gt 0 ]; then for i in "${cfg[@]}"; do
  printf '\n%sconfig: %s%s\n' "$B" "${IDS[$i]}" "$X"
  case "${IDS[$i]}" in
    shell)
      for f in .zprofile .zshrc; do t="$HOME/$f"
        if [ -L "$t" ] && [ "$(readlink "$t")" = "$DIR/shell/$f" ]; then
          rm "$t"; [ -f "$t.pre-dotfiles.bak" ] && mv "$t.pre-dotfiles.bak" "$t"
          echo "  $t: replaced old symlink with your own file"; fi
        put_block "$t" "$MARK_START" "$MARK_END" "[ -f \"$DIR/shell/$f\" ] && source \"$DIR/shell/$f\""
      done ;;
    git)
      GC="$HOME/.gitconfig"; [ -L "$GC" ] && GC="$(perl -MCwd -e 'print Cwd::realpath(shift)' "$GC")"; touch "$GC"
      # repoint an include left by another checkout of this repo (a worktree, an old clone), else add one
      old="$(git config --file "$GC" --get-all include.path 2>/dev/null | while IFS= read -r p; do
        [ "$p" != "$DIR/git/.gitconfig" ] && [ "${p%/git/.gitconfig}/git/.gitconfig" = "$p" ] &&
          [ -f "${p%/git/.gitconfig}/install.sh" ] && echo "$p"; done | head -1)"
      if grep -qsF "$DIR/git/.gitconfig" "$GC"; then :
      elif [ -n "$old" ]; then git config --file "$GC" --replace-all include.path "$DIR/git/.gitconfig" "^$old\$"
        echo "  $GC: include repointed from $old"
      else git config --file "$GC" --add include.path "$DIR/git/.gitconfig"; fi
      [ -z "$(git config --get user.email 2>/dev/null || true)" ] && \
        echo "  set identity:  git config --global user.name '...'  &&  git config --global user.email '...'" || true
      command -v gh >/dev/null && ! gh auth status >/dev/null 2>&1 && \
        echo "  log in to github (browser, token goes in keychain):  gh auth login" || true ;;
    ghostty-theme) [ -x "$DIR/ghostty/install.sh" ] && "$DIR/ghostty/install.sh" ;;
    ghostty-tabs)
      mkdir -p "$(dirname "$GHOSTTY_CONFIG")"
      put_block "$GHOSTTY_CONFIG" "$TABS_START" "$TABS_END" "config-file = ?$DIR/ghostty/tabs.conf"
      echo "  new tabs pick it up; quit and reopen ghostty for the tab bar style" ;;
    nvim)
      t="$HOME/.config/nvim"; mkdir -p "$HOME/.config"
      if [ -L "$t" ] && [ -f "$(readlink "$t")/lua/dotfiles/helpers.lua" ]; then rm "$t"   # a link to another checkout of this repo
      elif [ -e "$t" ] || [ -L "$t" ]; then mv "$t" "$t.bak-$STAMP"; echo "  kept your $t as $t.bak-$STAMP"; fi
      ln -s "$DIR/nvim" "$t"; echo "  $t -> $DIR/nvim"
      if command -v nvim >/dev/null; then
        nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 && echo "  plugins installed at the versions in nvim/lazy-lock.json"
        echo "  the first nvim start installs language tools in the background (a minute or two)"
      else echo "  nvim isn't installed yet: ./install.sh --only neovim"; fi ;;
    skills)
      for t in "$HOME/.agents/skills" "$HOME/.claude/skills"; do mkdir -p "$t"
        for s in "$DIR"/agents/skills/*/; do n="$(basename "$s")"; d="$t/$n"
          if [ -d "$d" ] && [ ! -f "$d/.dotfiles" ] && ! diff -rq -x __pycache__ "$s" "$d" >/dev/null 2>&1; then
            echo "  skip $d: you already have a different skill with this name"; continue; fi
          rsync -a --exclude __pycache__ "$s" "$d/"; touch "$d/.dotfiles"
        done
      done
      for s in "$DIR"/agents/skills/*/; do n="$(basename "$s")"
        [ -f "$HOME/.claude/commands/$n.md" ] && echo "  note: ~/.claude/commands/$n.md is an older slash command with the same name; remove it to use only the skill"
      done; true ;;
    macos)   bash "$DIR/macos/defaults.sh" ;;
    claude)
      if command -v claude >/dev/null; then echo "  already installed: $(command -v claude), leaving it as is"
      else curl -fsSL https://claude.ai/install.sh | bash; fi ;;
    aws)
      if [ -t 0 ] && [ -t 1 ]; then "$DIR/bin/awssetup" || echo "  awssetup didn't finish; run it again any time: awssetup"
      else echo "  needs a terminal (it asks questions and opens a browser). run later: awssetup"; fi ;;
  esac
done; fi

printf '\n%sdone.%s open a new terminal (or run: exec zsh) to pick up shell changes.\n' "$G" "$X"

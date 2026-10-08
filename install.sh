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
IDS=(); CLASSES=(); DESCS=(); KINDS=(); TARGETS=()
cls=misc
while IFS= read -r line || [ -n "$line" ]; do
  if [[ "$line" =~ ^#[[:space:]]+([a-z][a-z-]*)[[:space:]]*$ ]]; then
    cls="${BASH_REMATCH[1]}"
  elif [[ "$line" =~ ^(brew|cask)[[:space:]]+\"([^\"]+)\"(.*#[[:space:]](.*))?$ ]]; then
    k="${BASH_REMATCH[1]}"; full="${BASH_REMATCH[2]}"; dsc="${BASH_REMATCH[4]:-}"
    IDS+=("${full##*/}"); CLASSES+=("$cls"); DESCS+=("${dsc:-${full##*/}}")
    [ "$k" = cask ] && KINDS+=(cask) || KINDS+=(formula); TARGETS+=("$full")
  fi
done < "$DIR/Brewfile"

add_cfg(){ IDS+=("$1"); CLASSES+=(config); DESCS+=("$2"); KINDS+=(config); TARGETS+=("$1"); }
add_cfg shell   "append a source line to ~/.zprofile + ~/.zshrc"
add_cfg git     "include repo git config in ~/.gitconfig"
add_cfg ghostty-theme "ChessKing + cadillac themes + gtheme picker"
add_cfg skills  "agent skills -> ~/.agents/skills + ~/.claude/skills"
add_cfg macos   "key repeat, file extensions, screenshots"

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
        ghostty-theme) for t in "$DIR"/ghostty/themes/*; do [ -f "$HOME/.config/ghostty/themes/${t##*/}" ] || return 1; done
                       WHERE="$HOME/.config/ghostty/themes ($(ls "$DIR/ghostty/themes" | wc -l | tr -d ' ') themes)" ;;
        skills)  for s in "$DIR"/agents/skills/*/; do for t in "$HOME/.agents/skills" "$HOME/.claude/skills"; do
                   diff -rq -x __pycache__ -x .dotfiles "$s" "$t/$(basename "$s")" >/dev/null 2>&1 || return 1; done; done
                 WHERE="~/.agents/skills + ~/.claude/skills ($(ls "$DIR/agents/skills" | wc -l | tr -d ' ') skills)" ;;
        macos)   [ "$(defaults read -g KeyRepeat 2>/dev/null || echo x)" = 2 ] && WHERE="KeyRepeat=2 (applied)" || return 1 ;;
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
  chosen="$( { printf 'ALL\t(re)install everything\n'
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
  wa=0; wc=" "; wi=" "
  while IFS= read -r t; do case "$t" in
    ALL) wa=1 ;; class:*) wc="$wc${t#class:} " ;; *) wi="$wi$t " ;; esac; done <<< "$chosen"
  for i in "${!IDS[@]}"; do
    if [ "$wa" = 1 ] || [[ "$wc" == *" ${CLASSES[$i]} "* ]] || [[ "$wi" == *" ${IDS[$i]} "* ]]; then SEL+=("$i"); fi
  done
fi
[ "${#SEL[@]}" -eq 0 ] && { echo "nothing to install."; exit 0; }

# ---------- install selected ----------
pkg=(); cfg=()
for i in "${SEL[@]}"; do [ "${KINDS[$i]}" = config ] && cfg+=("$i") || pkg+=("$i"); done

if [ "${#pkg[@]}" -gt 0 ]; then
  tmp="$(mktemp)"; grep -E '^tap ' "$DIR/Brewfile" >> "$tmp" || true
  for i in "${pkg[@]}"; do
    [ "${KINDS[$i]}" = cask ] && printf 'cask "%s", args: { adopt: true }\n' "${TARGETS[$i]}" >> "$tmp" \
                              || printf 'brew "%s"\n' "${TARGETS[$i]}" >> "$tmp"
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
        touch "$t"
        if grep -qsF "$MARK_START" "$t"; then echo "  $t: dotfiles block already present, left as is"
        else printf '\n%s\n[ -f "%s" ] && source "%s"\n%s\n' "$MARK_START" "$DIR/shell/$f" "$DIR/shell/$f" "$MARK_END" >> "$t"
             echo "  $t: appended dotfiles block, your existing lines are untouched"; fi
      done ;;
    git)
      GC="$HOME/.gitconfig"; [ -L "$GC" ] && GC="$(perl -MCwd -e 'print Cwd::realpath(shift)' "$GC")"; touch "$GC"
      grep -qsF "$DIR/git/.gitconfig" "$GC" || git config --file "$GC" --add include.path "$DIR/git/.gitconfig"
      [ -z "$(git config --get user.email 2>/dev/null || true)" ] && \
        echo "  set identity:  git config --global user.name '...'  &&  git config --global user.email '...'" || true
      command -v gh >/dev/null && ! gh auth status >/dev/null 2>&1 && \
        echo "  log in to github (browser, token goes in keychain):  gh auth login" || true ;;
    ghostty-theme) [ -x "$DIR/ghostty/install.sh" ] && "$DIR/ghostty/install.sh" ;;
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
  esac
done; fi

printf '\n%sdone.%s open a new terminal (or run: exec zsh) to pick up shell changes.\n' "$G" "$X"

#!/usr/bin/env bash
# dotfiles installer + health check. safe to re-run over an existing setup: it detects
# what's already installed (green check + where) and only offers to add the diff.
#
#   ./install.sh          health-check, then fuzzy-pick what to install from the diff
#   ./install.sh --all    install everything missing (no prompt)
#   ./install.sh --check  health-check only (report; installs nothing)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=pick
case "${1:-}" in
  --all) MODE=all ;; --check) MODE=check ;; ""|--pick) MODE=pick ;;
  *) echo "usage: install.sh [--all|--check]" >&2; exit 2 ;;
esac

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
add_cfg shell   "link .zprofile + .zshrc (stow)"
add_cfg git     "include repo git config in ~/.gitconfig"
add_cfg ghostty-theme "ChessKing theme + gtheme picker"
add_cfg claude  "laymans slash command"
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
        shell)   [ -L "$HOME/.zshrc" ] && WHERE="$HOME/.zshrc -> $(readlink "$HOME/.zshrc")" || return 1 ;;
        git)     grep -qsF "$DIR/git/.gitconfig" "$HOME/.gitconfig" && WHERE="$HOME/.gitconfig [include]" || return 1 ;;
        ghostty-theme) [ -f "$HOME/.config/ghostty/themes/ChessKing" ] && WHERE="$HOME/.config/ghostty/themes/ChessKing" || return 1 ;;
        claude)  [ -f "$HOME/.claude/commands/laymans.md" ] && WHERE="$HOME/.claude/commands/laymans.md" || return 1 ;;
        macos)   [ "$(defaults read -g KeyRepeat 2>/dev/null || echo x)" = 2 ] && WHERE="KeyRepeat=2 (applied)" || return 1 ;;
      esac ;;
  esac
  return 0
}

# ---------- health check ----------
printf '\n%shealth check%s  %s%s%s\n\n' "$B" "$X" "$D" "$DIR" "$X"
MISSING=()
for i in "${!IDS[@]}"; do
  if detect "$i"; then printf '  %s✓%s %-18s %s%s%s\n' "$G" "$X" "${IDS[$i]}" "$D" "$WHERE" "$X"
  else printf '  %s✗%s %-18s %s%s%s\n' "$R" "$X" "${IDS[$i]}" "$D" "${DESCS[$i]}" "$X"; MISSING+=("$i"); fi
done

if [ "${#MISSING[@]}" -eq 0 ]; then printf '\n%s✓ everything is installed.%s\n' "$G" "$X"; exit 0; fi
printf '\n%s%s missing:%s ' "$Y" "${#MISSING[@]}" "$X"
for i in "${MISSING[@]}"; do printf '%s ' "${IDS[$i]}"; done; printf '\n'
[ "$MODE" = check ] && { printf '\nrun %s./install.sh%s to choose what to add.\n' "$B" "$X"; exit 0; }

# ---------- choose from the diff ----------
SEL=()
if [ "$MODE" = all ]; then
  SEL=("${MISSING[@]}")
else
  command -v fzf >/dev/null 2>&1 || brew install fzf >/dev/null
  if [ ! -t 0 ] || [ ! -t 1 ]; then
    printf '\nnot a terminal — re-run with %s--all%s to install everything missing.\n' "$B" "$X"; exit 0; fi
  chosen="$( { printf 'ALL\teverything missing (%s)\n' "${#MISSING[@]}"
      for c in $(for i in "${MISSING[@]}"; do echo "${CLASSES[$i]}"; done | sort -u); do
        n=0; for i in "${MISSING[@]}"; do [ "${CLASSES[$i]}" = "$c" ] && n=$((n+1)); done
        printf 'class:%s\twhole %s class (%s)\n' "$c" "$c" "$n"; done
      for i in "${MISSING[@]}"; do printf '%s\t%s — %s\n' "${IDS[$i]}" "${CLASSES[$i]}" "${DESCS[$i]}"; done
    } | fzf -m --delimiter='\t' --with-nth=1,2 --height=90% --layout=reverse --border \
        --prompt='install > ' --header=$'Tab = mark  ·  Enter = install marked  ·  Esc = cancel' \
      | cut -f1 )"
  [ -z "$chosen" ] && { echo "nothing selected."; exit 0; }
  wa=0; wc=" "; wi=" "
  while IFS= read -r t; do case "$t" in
    ALL) wa=1 ;; class:*) wc="$wc${t#class:} " ;; *) wi="$wi$t " ;; esac; done <<< "$chosen"
  for i in "${MISSING[@]}"; do
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
      command -v stow >/dev/null 2>&1 || brew install stow >/dev/null
      for f in .zshrc .zprofile; do t="$HOME/$f"; [ -e "$t" ] && [ ! -L "$t" ] && mv "$t" "$t.pre-dotfiles.bak"; done
      stow --dir="$DIR" --target="$HOME" --restow shell ;;
    git)
      GC="$HOME/.gitconfig"; [ -L "$GC" ] && rm -f "$GC"; touch "$GC"
      grep -qsF "$DIR/git/.gitconfig" "$GC" || git config --file "$GC" --add include.path "$DIR/git/.gitconfig"
      [ -z "$(git config --get user.email 2>/dev/null || true)" ] && \
        echo "  set identity:  git config --global user.name '...'  &&  git config --global user.email '...'" || true ;;
    ghostty-theme) [ -x "$DIR/ghostty/install.sh" ] && "$DIR/ghostty/install.sh" ;;
    claude)  mkdir -p "$HOME/.claude/commands"; cp "$DIR"/claude/commands/*.md "$HOME/.claude/commands/" 2>/dev/null || true ;;
    macos)   bash "$DIR/macos/defaults.sh" ;;
  esac
done; fi

printf '\n%sdone.%s open a new terminal (or run: exec zsh) to pick up shell changes.\n' "$G" "$X"

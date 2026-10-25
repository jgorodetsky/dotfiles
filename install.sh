#!/usr/bin/env bash
# dotfiles installer + health check. safe to re-run over an existing setup: it detects
# what's already installed (green check + where) and only offers to add the diff.
# it never replaces your files: shell and git get a source/include line appended,
# anything it would change gets a timestamped .bak first. lines you already had in
# ~/.zshrc / ~/.zprofile are decided first, before the picker (shell/adopt.zsh): you see
# where each one goes and pick merge, keep or overwrite. merge deletes the ones the repo
# already does and moves the rest to ~/.zshrc.local / ~/.zprofile.local.
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

# the screens: its own screen like vim, a step bar, arrow-key menus, spinner rows
. "$DIR/lib/ui.sh"
. "$DIR/lib/upgrade.sh"

# what kind of machine this is (shown in the header; install choices will use it next)
case "$(uname -s)" in
  Darwin) OSNAME="macOS $(sw_vers -productVersion 2>/dev/null)" ;;
  Linux)  grep -qi microsoft /proc/version 2>/dev/null && OSNAME="WSL" || OSNAME="Linux" ;;
  *)      OSNAME="$(uname -s)" ;;
esac
id -Gn 2>/dev/null | tr ' ' '\n' | grep -qxE 'admin|sudo|wheel' && ADMIN="admin" || ADMIN="no admin"

# ---------- prereqs: xcode CLT + homebrew (needed before we can check anything) ----------
xcode-select -p >/dev/null 2>&1 || xcode-select --install 2>/dev/null || true
if ! command -v brew >/dev/null 2>&1; then
  echo "installing homebrew (asks for your mac password once)..."
  # homebrew's hands-free mode can't prompt for sudo, so prompt here and let it reuse that
  [ -t 0 ] && sudo -v
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
add_cfg shell   "loader line in ~/.zprofile + ~/.zshrc, sorts the other lines in them"
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
VERSIONS="$(brew list --versions 2>/dev/null || true)"
CASKS="$(brew list --cask -1 2>/dev/null || true)"
WHERE=""; STATE=""; REASON=""; FIX=""
# other_checkout PATH SUBPATH - the repo folder PATH points into, if it's another copy of this repo
other_checkout(){ local d="${1%"$2"}"; [ "$d" != "$1" ] && [ "$d" != "$DIR" ] && [ -f "$d/install.sh" ] && echo "${d/#$HOME/~}"; }
set_state(){ STATE="$1"; REASON="$2"; FIX="$3"; }
# lines in ~/.zprofile / ~/.zshrc besides the loader: SORT_N in all, SORT_FILES the files that have some
sort_counts(){ local f r m t c; SORT_N=0; SORT_FILES=""
  command -v zsh >/dev/null || return 0
  for f in .zprofile .zshrc; do [ -s "$HOME/$f" ] || continue
    read -r r m t c < <(zsh "$DIR/shell/adopt.zsh" --summary "$HOME/$f" 2>/dev/null || echo 0 0 0 0)
    [ $((r + m + t + c)) -gt 0 ] || continue
    SORT_N=$((SORT_N + r + m + t + c)); SORT_FILES="$SORT_FILES $f"
  done; }
detect(){ # $1 index -> 0 installed (sets WHERE) / 1 not (sets STATE missing|elsewhere|differs, REASON, FIX)
  local id="${IDS[$1]}" kind="${KINDS[$1]}" p v o f n m; WHERE=""; VER=""; STATE=ok; REASON=""; FIX=""
  case "$kind" in
    formula)
      printf '%s\n' "$FORMULAE" | grep -qxE "($id|.*/$id)" || { set_state missing "not installed" install; return 1; }
      p="$(command -v "$id" 2>/dev/null || echo "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/$id")"
      v="$(printf '%s\n' "$VERSIONS" | awk -v n="$id" '$1 == n { print $NF }')"
      WHERE="$p${v:+  ($v)}"; VER="$v" ;;
    cask)
      if printf '%s\n' "$CASKS" | grep -qx "$id"; then WHERE="brew cask: $id"
      elif [ "$id" = ghostty ] && [ -d /Applications/Ghostty.app ]; then WHERE="/Applications/Ghostty.app (non-brew)"
      elif [ "$id" = visual-studio-code ] && [ -d "/Applications/Visual Studio Code.app" ]; then WHERE="/Applications/Visual Studio Code.app (non-brew)"
      else set_state missing "not installed" install; return 1; fi ;;
    config)
      case "$id" in
        shell)   sort_counts; m=""; [ "$SORT_N" -gt 0 ] && m=", $SORT_N lines to sort"
                 for f in .zprofile .zshrc; do grep -qsF "$DIR/shell/$f" "$HOME/$f" && continue
                   o="$(grep -oE '"/[^"]+/shell/\.z(profile|shrc)"' "$HOME/$f" 2>/dev/null | head -1 | tr -d '"')"
                   o="$(other_checkout "$o" "/shell/$f")"
                   [ -n "$o" ] && { set_state elsewhere "set up from $o, not this folder$m" "switch here"; return 1; }
                   set_state missing "not set up$m" "set up"; return 1; done
                 case "$MODE" in pick) f="next step" ;; all) f="merged next" ;; *) f="dot fix" ;; esac
                 [ "$SORT_N" -gt 0 ] && { set_state sort "$SORT_N lines in${SORT_FILES// / ~/} to sort" "$f"; return 1; }
                 WHERE="~/.zprofile + ~/.zshrc [dotfiles block, nothing else]" ;;
        git)     grep -qsF "$DIR/git/.gitconfig" "$HOME/.gitconfig" && { WHERE="$HOME/.gitconfig [include]"; return 0; }
                 o="$(git config --file "$HOME/.gitconfig" --get-all include.path 2>/dev/null | while IFS= read -r p; do other_checkout "$p" /git/.gitconfig; done | head -1)"
                 [ -n "$o" ] && { set_state elsewhere "set up from $o, not this folder" "switch here"; return 1; }
                 set_state missing "not set up" "set up"; return 1 ;;
        ghostty-tabs) if ! grep -qsF "config-file = ?$DIR/ghostty/tabs.conf" "$GHOSTTY_CONFIG"; then
                        o="$(grep -oE 'config-file = \?/.+/ghostty/tabs\.conf' "$GHOSTTY_CONFIG" 2>/dev/null | sed 's/config-file = ?//' | head -1)"
                        o="$(other_checkout "$o" /ghostty/tabs.conf)"
                        [ -n "$o" ] && { set_state elsewhere "set up from $o, not this folder" "switch here"; return 1; }
                        set_state missing "not set up" "set up"; return 1; fi
                      WHERE="$GHOSTTY_CONFIG [dotfiles tabs block]" ;;
        nvim)    p="$(readlink "$HOME/.config/nvim" 2>/dev/null || true)"
                 if [ "$p" != "$DIR/nvim" ]; then
                   o="$(other_checkout "$p" /nvim)"
                   [ -n "$o" ] && { set_state elsewhere "set up from $o, not this folder" "switch here"; return 1; }
                   [ -e "$HOME/.config/nvim" ] && { set_state differs "you have your own ~/.config/nvim" "yours, kept"; return 1; }
                   set_state missing "not set up" "set up"; return 1; fi
                 WHERE="~/.config/nvim -> $DIR/nvim" ;;
        ghostty-theme) for t in "$DIR"/ghostty/themes/*; do [ -f "$HOME/.config/ghostty/themes/${t##*/}" ] || { set_state missing "themes not copied" "copy them"; return 1; }; done
                       WHERE="$HOME/.config/ghostty/themes ($(ls "$DIR/ghostty/themes" | wc -l | tr -d ' ') themes)" ;;
        skills)  n=0; m=0; o=""; for s in "$DIR"/agents/skills/*/; do for t in "$HOME/.agents/skills" "$HOME/.claude/skills"; do
                   f="$(basename "$s")"
                   if [ ! -d "$t/$f" ]; then m=$((m + 1))
                   elif ! diff -rq -x __pycache__ -x .dotfiles "$s" "$t/$f" >/dev/null 2>&1; then n=$((n + 1))
                     # an installed copy that matches another checkout (say uncommitted edits in ~/dotfiles)
                     for p in $(git -C "$DIR" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p'); do
                       [ "$p" != "$DIR" ] && diff -rq -x __pycache__ -x .dotfiles "$p/agents/skills/$f" "$t/$f" >/dev/null 2>&1 && o="${p/#$HOME/~}"; done
                   fi; done; done
                 [ "$n" -gt 0 ] && [ -n "$o" ] && { set_state differs "$n cop$([ "$n" = 1 ] && echo y || echo ies) match $o (yours)" "fine to leave"; return 1; }
                 [ "$n" -gt 0 ] && { set_state differs "$n installed cop$([ "$n" = 1 ] && echo y || echo ies) differ from the repo" "yours, kept"; return 1; }
                 [ "$m" -gt 0 ] && { set_state missing "$m not installed" install; return 1; }
                 WHERE="~/.agents/skills + ~/.claude/skills ($(ls "$DIR/agents/skills" | wc -l | tr -d ' ') skills)" ;;
        macos)   { [ "$(defaults read -g KeyRepeat 2>/dev/null || echo x)" = 2 ] &&
                   [ "$(defaults export com.apple.symbolichotkeys - 2>/dev/null | plutil -extract AppleSymbolicHotKeys.160.value.parameters json -o - - 2>/dev/null)" = "[49,18,1048576]" ] &&
                   [ "$(defaults export com.apple.symbolichotkeys - 2>/dev/null | plutil -extract AppleSymbolicHotKeys.240.value.parameters json -o - - 2>/dev/null)" = "[65535,123,9175040]" ]; } ||
                   { set_state missing "settings not applied" apply; return 1; }
                 WHERE="KeyRepeat=2, cmd+1 apps, ctrl+opt tiling (applied)" ;;
        claude)  p="$(command -v claude 2>/dev/null)" || { set_state missing "not installed" install; return 1; }
                 case "$p" in "$(brew --prefix)"/*) WHERE="$p (homebrew; updated by brew via CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE)" ;;
                              *) WHERE="$p (native, auto-updates)" ;; esac ;;
        aws)     grep -qs '^\[sso-session ' "${AWS_CONFIG_FILE:-$HOME/.aws/config}" || { set_state missing "never set up" "run awssetup"; return 1; }
                 WHERE="${AWS_CONFIG_FILE:-~/.aws/config} ($(grep -c '^\[profile ' "${AWS_CONFIG_FILE:-$HOME/.aws/config}") profiles)" ;;
      esac ;;
  esac
  return 0
}

# check everything first, then draw one screen
branch="$(git -C "$DIR" branch --show-current 2>/dev/null || true)"
UI_HEAD="${DIR/#$HOME/~}${branch:+ ($branch)} · $OSNAME $(uname -m) · $ADMIN"
[ "$UI_TTY" = 1 ] && printf '%schecking %s items…%s' "$D" "${#IDS[@]}" "$X"
upgrade_start   # newer versions, looked up in the background while the rest is checked
MISSING=(); STATUS=(); REASONS=(); FIXES=(); WHERES=(); nok=0; nlook=0; nmiss=0
for i in "${!IDS[@]}"; do
  if detect "$i"; then STATUS[$i]=ok; WHERES[$i]="$WHERE"; nok=$((nok + 1))
  else STATUS[$i]=$STATE; REASONS[$i]=$REASON; FIXES[$i]=$FIX; MISSING+=("$i")
    if [ "$STATE" = missing ]; then nmiss=$((nmiss + 1)); else nlook=$((nlook + 1)); fi; fi
done
# refresh one item after a step changed it
recheck(){ local i=$1 j
  if detect "$i"; then STATUS[$i]=ok; WHERES[$i]="$WHERE"; else STATUS[$i]=$STATE; REASONS[$i]=$REASON; FIXES[$i]=$FIX; fi
  MISSING=(); nok=0; nlook=0; nmiss=0
  for j in "${!IDS[@]}"; do case "${STATUS[$j]}" in
    ok) nok=$((nok + 1)) ;; missing) nmiss=$((nmiss + 1)); MISSING+=("$j") ;; *) nlook=$((nlook + 1)); MISSING+=("$j") ;; esac; done; }

# this machine: settings it has that the repo sets too (optional to clean up)
NEED_N=(); NEED_W=(); NEED_F=(); gsame=(); gdiff=()
for k in $(comm -12 <(git config --file "$HOME/.gitconfig" --list 2>/dev/null | cut -d= -f1 | grep -v '^include\.' | sort -u) \
                    <(git config --file "$DIR/git/.gitconfig" --list | cut -d= -f1 | sort -u)); do
  if [ "$(git config --file "$HOME/.gitconfig" --get-all "$k")" = "$(git config --file "$DIR/git/.gitconfig" --get-all "$k")" ]; then gsame+=("${k##*.}"); else gdiff+=("${k##*.}"); fi
done
[ "${#gsame[@]}" -gt 0 ] && { NEED_N+=("~/.gitconfig"); NEED_W+=("${#gsame[@]} also set in the repo: ${gsame[*]}"); NEED_F+=(optional); }
[ "${#gdiff[@]}" -gt 0 ] && { NEED_N+=("~/.gitconfig"); NEED_W+=("${#gdiff[@]} set differently (repo wins): ${gdiff[*]}"); NEED_F+=(optional); }
extra=($(comm -23 <({ brew leaves --installed-on-request; brew list --cask -1; } 2>/dev/null | sed 's|.*/||' | sort -u) \
                  <(grep -oE '^(brew|cask) "[^"]+"' "$DIR/Brewfile" | sed 's/.*"\(.*\)"/\1/; s|.*/||' | sort -u)))
[ "${#extra[@]}" -gt 0 ] && { NEED_N+=(brew); NEED_W+=("${#extra[@]} not in the Brewfile: ${extra[*]:0:4}…"); NEED_F+=(optional); }
# newer versions of what you installed, and tools too old for brew to install with
upgrade_scan
if [ -n "$CLT_OLD" ]; then NEED_N+=("xcode tools"); NEED_W+=("command line tools $CLT_OLD, too old for this macOS"); NEED_F+=("dot upgrade"); fi
if [ "${#UP_N[@]}" -gt 0 ]; then
  up="${#UP_N[@]} newer versions: ${UP_N[*]:0:3}…"; [ "$UP_BIG" -gt 0 ] && up="${#UP_N[@]} newer, $UP_BIG to check first: ${UP_N[*]:0:2}…"
  NEED_N+=(updates); NEED_W+=("$up"); NEED_F+=("dot upgrade"); fi
[ "$UI_TTY" = 1 ] && printf '\r\033[K'

mark(){ case "$1" in ok) printf '%s✓%s' "$G" "$X" ;; missing) printf '%s✗%s' "$R" "$X" ;; *) printf '%s~%s' "$Y" "$X" ;; esac; }
cells(){ local n=$1 c="$2" s=""; while [ "$n" -gt 0 ]; do s="$s$c"; n=$((n - 1)); done; printf '%s' "$s"; }

# the health screen: what needs you first, the fine ones folded into one line per group
check_screen(){
  local i n pk=0 tot g y r rw cls cnt line piece pkn=""
  n=${#NEED_N[@]}; tot=$((nok + nlook + nmiss + n))
  [ "$UI_ON" = 1 ] || printf '\n%sdotfiles health%s  %s%s%s\n' "$B" "$X" "$D" "$UI_HEAD" "$X"
  # 30 cells: green ok, yellow to look at, red missing (anything not ok gets at least one)
  r=0; y=0; [ "$nmiss" -gt 0 ] && r=$(( (nmiss * 30 + tot - 1) / tot ))
  [ $((nlook + n)) -gt 0 ] && y=$(( ((nlook + n) * 30 + tot - 1) / tot )); g=$((30 - r - y))
  [ -t 1 ] && printf '%s%s%s%s%s%s%s  ' "$G" "$(cells $g █)" "$Y" "$(cells $y █)" "$R" "$(cells $r █)" "$X"
  printf '%s ok · %s to look at · %s missing\n\n' "$nok" "$((nlook + n))" "$nmiss"
  if [ $(( ${#MISSING[@]} + n )) -eq 0 ]; then printf '  %s✓ nothing needs you%s\n\n' "$G" "$X"
  else
    printf '%sneeds you%s\n' "$B" "$X"
    rw=$(( UI_W - 34 )); [ "$rw" -gt 52 ] && rw=52
    for i in "${!MISSING[@]}"; do i=${MISSING[$i]}
      if [ "${KINDS[$i]}" != config ] && [ "${STATUS[$i]}" = missing ]; then pk=$((pk + 1)); pkn="$pkn ${IDS[$i]}"; fi; done
    for i in "${!MISSING[@]}"; do i=${MISSING[$i]}
      [ "${KINDS[$i]}" != config ] && [ "${STATUS[$i]}" = missing ] && [ "$pk" -gt 3 ] && continue
      printf '  %s %s %s  %s%s%s\n' "$(mark "${STATUS[$i]}")" "$(pad "${IDS[$i]}" 13)" "$(pad "$(cut_to "${REASONS[$i]}" "$rw")" "$rw")" "$D" "${FIXES[$i]}" "$X"
    done
    [ "$pk" -gt 3 ] && printf '  %s %s %s  %sinstall%s\n' "$(mark missing)" "$(pad "$pk packages" 13)" "$(pad "$(cut_to "not installed:$pkn" "$rw")" "$rw")" "$D" "$X"
    for i in "${!NEED_N[@]}"; do
      printf '  %s %s %s  %s%s%s\n' "$(mark look)" "$(pad "${NEED_N[$i]}" 13)" "$(pad "$(cut_to "${NEED_W[$i]}" "$rw")" "$rw")" "$D" "${NEED_F[$i]}" "$X"; done
    echo
  fi
  printf '%sfine (%s)%s\n' "$B" "$nok" "$X"; line=""
  for cls in $(printf '%s\n' "${CLASSES[@]}" | awk '!seen[$0]++'); do
    cnt=0; for i in "${!IDS[@]}"; do [ "${CLASSES[$i]}" = "$cls" ] && [ "${STATUS[$i]}" = ok ] && cnt=$((cnt + 1)); done
    [ "$cnt" -gt 0 ] || continue
    piece="$cls $cnt"
    if [ -n "$line" ] && [ $(( ${#line} + ${#piece} + 5 )) -gt $(( UI_W - 2 < 70 ? UI_W - 2 : 70 )) ]; then printf '  %s%s%s\n' "$D" "$line" "$X"; line=""; fi
    line="${line:+$line · }$piece"
  done
  [ -n "$line" ] && printf '  %s%s%s\n' "$D" "$line" "$X"
  return 0; }

# the three boxes for one shell file: deleted (the repo has it), moved (only yours), you pick
pack(){ # WIDTH NAME... -> lines of names joined by two spaces, repeats counted (x2)
  local w=$1 out="" s c k; shift
  local -a seen=() cnt=()
  for s in "$@"; do k=-1; for c in "${!seen[@]}"; do [ "${seen[$c]}" = "$s" ] && k=$c; done
    if [ "$k" -ge 0 ]; then cnt[$k]=$(( cnt[$k] + 1 )); else seen+=("$s"); cnt+=(1); fi; done
  for c in "${!seen[@]}"; do s="${seen[$c]}"; [ "${cnt[$c]}" -gt 1 ] && s="$s ×${cnt[$c]}"; s="$(cut_to "$s" "$w")"
    if [ -n "$out" ] && [ $(( ${#out} + ${#s} + 2 )) -gt "$w" ]; then printf '%s\n' "$out"; out="$s"; else out="${out:+$out  }$s"; fi
  done
  [ -n "$out" ] && printf '%s\n' "$out"; return 0; }
buckets(){ # PLAN (adopt.zsh --plan rows) FILE
  local plan="$1" f="$2" n k s dg nt l t w bw inner h i side=1 pre="the repo's "
  local -a dl=() ml=() al=() A=() M=() Q=()
  while IFS=$'\t' read -r n k s dg nt l; do
    w=""; [ "$dg" = 1 ] && w=" ⚠"
    case "$k" in
      dup) dl+=("$s") ;;
      mine) if [ "$dg" = 1 ]; then al+=("$s ⚠ can destroy work"); else ml+=("$s"); fi ;;
      twin) t="${nt#"$pre"}"; t="${t%% *}"; al+=("$s = repo's $t$w") ;;
      conflict) al+=("$s ≠ the repo's$w") ;;
    esac
  done <<< "$plan"
  bw=$(( ( (UI_W < 104 ? UI_W : 104) - 4 ) / 3 )); [ "$bw" -lt 22 ] && { side=0; bw=$(( UI_W < 54 ? UI_W - 4 : 50 )); }
  inner=$((bw - 4))
  while IFS= read -r l; do A+=("$l"); done < <(pack "$inner" ${dl[@]+"${dl[@]}"})
  while IFS= read -r l; do M+=("$l"); done < <(pack "$inner" ${ml[@]+"${ml[@]}"})
  for s in ${al[@]+"${al[@]}"}; do Q+=("$(cut_to "$s" "$inner")"); done
  [ "${#A[@]}" -gt 0 ] || A=("(none)"); [ "${#M[@]}" -gt 0 ] || M=("(none)"); [ "${#Q[@]}" -gt 0 ] || Q=("(none)")
  top(){ local t="$1" c="$2" fill; fill=$(( bw - 4 - ${#t} )); printf '%s┌ %s%s%s %s┐%s' "$D" "$c" "$t" "$D" "$(cells $fill ─)" "$X"; }
  mid(){ printf '%s│%s %s %s│%s' "$D" "$X" "$(pad "$1" "$inner")" "$D" "$X"; }
  bot(){ printf '%s└%s┘%s' "$D" "$(cells $((bw - 2)) ─)" "$X"; }
  if [ "$side" = 1 ]; then
    h=${#A[@]}; [ ${#M[@]} -gt "$h" ] && h=${#M[@]}; [ ${#Q[@]} -gt "$h" ] && h=${#Q[@]}
    printf '%s %s %s\n' "$(top "delete (${#dl[@]})" "$D")" "$(top "move (${#ml[@]})" "$C")" "$(top "you pick (${#al[@]})" "$Y")"
    for ((i = 0; i < h; i++)); do printf '%s %s %s\n' "$(mid "${A[$i]:-}")" "$(mid "${M[$i]:-}")" "$(mid "${Q[$i]:-}")"; done
    printf '%s %s %s\n' "$(bot)" "$(bot)" "$(bot)"
    printf ' %s%s %s %s%s\n' "$D" "$(pad "the repo has them" "$bw")" "$(pad "~/$f.local" "$bw")" "questions next" "$X"
  else
    top "delete (${#dl[@]}): the repo has them" "$D"; echo; for l in "${A[@]}"; do mid "$l"; echo; done; bot; echo
    top "move (${#ml[@]}): ~/$f.local" "$C"; echo; for l in "${M[@]}"; do mid "$l"; echo; done; bot; echo
    top "you pick (${#al[@]})" "$Y"; echo; for l in "${Q[@]}"; do mid "$l"; echo; done; bot; echo
  fi
  return 0; }

# what a dry run (or the write) of adopt.zsh says, drawn on the menu rail
result_lines(){ local k a b c
  printf '%s│%s  %sresult%s\n' "$D" "$X" "$B" "$X"
  while IFS=$'\t' read -r k a b c; do case "$k" in
    rc)     printf '%s│%s    %s %s\n' "$D" "$X" "$(pad "$a" 18)" "$b" ;;
    local)  printf '%s│%s    %s gets %s: %s\n' "$D" "$X" "$(pad "$a" 18)" "$b" "$(cut_to "$c" $((UI_W - 36)))" ;;
    gone)   printf '%s│%s    %s %s line(s), kept in the backup\n' "$D" "$X" "$(pad deleted 18)" "$a" ;;
    same)   printf '%s│%s  %s✓%s your shell behaves the same: %s aliases · %s functions · %s env vars\n' "$D" "$X" "$G" "$X" "$a" "$b" "$c" ;;
    error)  printf '%s│%s  %s✗ %s%s\n' "$D" "$X" "$R" "$a" "$X" ;;
  esac; done <<< "$1"
  if printf '%s\n' "$1" | grep -q '^change'; then
    printf '%s│%s  %s~%s what changes in your shell %s(from the choices above)%s\n' "$D" "$X" "$Y" "$X" "$D" "$X"
    printf '%s\n' "$1" | awk -F'\t' '$1 == "change"' | while IFS=$'\t' read -r k a b c; do
      printf '%s│%s      %s %s %s\n' "$D" "$X" "$(pad "$b" 4)" "$a" "$(cut_to "${c#"$a "}" $((UI_W - 30)))"; done
  fi
  printf '%s│%s\n' "$D" "$X"; return 0; }

# step: the shell files. one screen per file: the boxes, merge / keep / overwrite, the questions, a dry run, then write
SHELL_ASKED=0; SHELL_KEEP=0; SHELL_WROTE=0
shell_step(){ local step=$1 f plan nd nm na tot n k s dg nt l t w pre="the repo's " res drop mine off undo gone mv
  local -a opts
  SHELL_ASKED=1
  for f in $SORT_FILES; do
    plan="$(zsh "$DIR/shell/adopt.zsh" --plan "$HOME/$f" 2>/dev/null || true)"
    [ -n "$plan" ] || continue
    nd=$(printf '%s\n' "$plan" | awk -F'\t' '$2 == "dup"' | wc -l | tr -d ' ')
    nm=$(printf '%s\n' "$plan" | awk -F'\t' '$2 == "mine" && $4 == 0' | wc -l | tr -d ' ')
    tot=$(printf '%s\n' "$plan" | wc -l | tr -d ' '); na=$((tot - nd - nm))
    ui_frame "$step"
    printf '%s~/%s%s  %s%s lines besides the loader%s\n\n' "$B" "$f" "$X" "$D" "$tot" "$X"
    buckets "$plan" "$f"; echo
    while :; do
      ui_menu "What should happen to ~/$f?" 0 "Merge|$nd deleted · $nm to ~/$f.local · $na you pick" \
        "Keep it as it is|nothing changes" "Overwrite|loader only, your lines stay in the backup" "See every line|then choose"
      [ "$UI_PICK" = 3 ] || break
      zsh "$DIR/shell/adopt.zsh" --list "$HOME/$f" 2>/dev/null | sed '1,3d'; echo
    done
    opts=(); drop=""; mine=""; off=""
    case "$UI_PICK" in
      1) RECEIPT+=("  ${D}·${X} ~/$f  kept as it is"); SHELL_KEEP=1; continue ;;
      2) opts=(--overwrite) ;;
      0) while IFS=$'\t' read -r n k s dg nt l; do
           w=""; [ "$dg" = 1 ] && w=" ⚠"
           case "$k" in
             twin) t="${nt#"$pre"}"; t="${t%% *}"
                   ui_menu "$s does the same as the repo's $t${w}"$'\n'"$l" 0 "Keep both|$s goes to ~/$f.local" "Use $t, drop $s|"
                   [ "$UI_PICK" = 1 ] && drop="$drop,$n" ;;
             conflict) ui_menu "$s clashes with the repo${w}"$'\n'"$l   ($nt)" 0 "The repo's wins|yours kept, commented out" "Yours wins|"
                   [ "$UI_PICK" = 1 ] && mine="$mine,$n" ;;
             mine) [ "$dg" = 1 ] || continue
                   ui_menu "$s can destroy work ⚠"$'\n'"$l" 0 "Keep it|moves to ~/$f.local" "Keep it, turned off|commented out" "Drop it|"
                   case "$UI_PICK" in 1) off="$off,$n" ;; 2) drop="$drop,$n" ;; esac ;;
           esac
         done <<< "$plan"
         [ -n "$drop" ] && opts+=(--drop "${drop#,}"); [ -n "$mine" ] && opts+=(--mine "${mine#,}"); [ -n "$off" ] && opts+=(--off "${off#,}") ;;
    esac
    res="$(zsh "$DIR/shell/adopt.zsh" --apply "$HOME/$f" ${opts[@]+"${opts[@]}"} --dry 2>/dev/null || true)"
    result_lines "$res"
    printf '%s\n' "$res" | grep -q '^error' && { RECEIPT+=("  ${R}✗${X} ~/$f  not sorted: the result wouldn't parse"); continue; }
    if [ "${opts[0]:-}" = --overwrite ]; then t=1; else t=0; fi
    ui_menu "Write it?" "$t" "Yes|backups go next to the files" "No|leave ~/$f as it is"
    if [ "$UI_PICK" = 1 ]; then RECEIPT+=("  ${D}·${X} ~/$f  left as it is"); SHELL_KEEP=1; continue; fi
    res="$(zsh "$DIR/shell/adopt.zsh" --apply "$HOME/$f" ${opts[@]+"${opts[@]}"} --no-check 2>/dev/null || true)"
    grep -qsF "$DIR/shell/$f" "$HOME/$f" || put_block "$HOME/$f" "$MARK_START" "$MARK_END" "[ -f \"$DIR/shell/$f\" ] && source \"$DIR/shell/$f\"" >/dev/null
    undo="$(printf '%s\n' "$res" | awk -F'\t' '$1 == "undo" { print $2 }')"
    gone="$(printf '%s\n' "$res" | awk -F'\t' '$1 == "gone" { print $2 }')"; mv="$(printf '%s\n' "$res" | awk -F'\t' '$1 == "local" { print $3 }')"
    RECEIPT+=("  ${G}✓${X} ~/$f  ${gone:-0} deleted, ${mv:-0} moved to ~/$f.local" "    ${D}undo: $undo${X}")
    printf '%s✓%s  written. %sundo: %s%s\n' "$G" "$X" "$D" "$undo" "$X"; SHELL_WROTE=1
  done
  return 0; }

# what picking each item does (the full list's panel)
does(){ case "$1" in
  shell)  echo "adds the loader line to ~/.zprofile and ~/.zshrc, then sorts any other lines in them (you see every change and confirm first)" ;;
  git)    echo "adds one include line to ~/.gitconfig that loads the repo's git settings (delta, aliases, credentials)" ;;
  ghostty-theme) echo "copies the themes into ~/.config/ghostty/themes and the gtheme picker" ;;
  ghostty-tabs)  echo "adds a block to Ghostty's config that loads the tab title rules (backup first)" ;;
  nvim)   echo "points ~/.config/nvim at the repo's editor setup (your own config is kept as a backup)" ;;
  skills) echo "copies the agent skills into ~/.agents/skills and ~/.claude/skills. for ones you've changed it asks first: keep yours, overwrite all, or choose each" ;;
  macos)  echo "sets key repeat, file extensions, screenshots folder, cmd+1 app shortcuts, window tiling keys" ;;
  claude) echo "installs Claude Code with its own installer (it updates itself after that)" ;;
  aws)    echo "runs awssetup: asks a few questions, opens the browser to log in, writes a profile per account" ;;
  *)      echo "installs it with Homebrew if it's missing (already installed: left as is)" ;;
esac; }

# the full list: fzf, search, tab to mark several, a panel explaining the highlighted row
pick_list(){ local PV i id c t chosen
  command -v fzf >/dev/null 2>&1 || brew install fzf >/dev/null
  PV="$(mktemp -d)"; UI_CLEAN="$UI_CLEAN $PV"
  { printf '%sfixes these, one at a time:%s\n\n' "$B" "$X"
    for i in ${FIXABLE[@]+"${FIXABLE[@]}"}; do printf '  %s %s  %s%s%s\n' "$(mark "${STATUS[$i]}")" "${IDS[$i]}" "$D" "$(does "${IDS[$i]}")" "$X"; done
    [ "${#FIXABLE[@]}" -eq 0 ] && printf '  %snothing needs fixing%s\n' "$G" "$X"
    for i in ${MISSING[@]+"${MISSING[@]}"}; do [ "${STATUS[$i]}" = differs ] && printf '\n  %sleft alone:%s %s - %s. pick it by name and it asks before replacing yours.\n' "$Y" "$X" "${IDS[$i]}" "${REASONS[$i]}"; done
  } > "$PV/fix"
  printf '%sre-applies all %s items, including the ones already ✓.%s\nsafe to rerun: packages already installed are left as is, config steps skip what is in place.\n' "$B" "${#IDS[@]}" "$X" > "$PV/all"
  for i in "${!IDS[@]}"; do id="${IDS[$i]}"
    { printf '%s %s%s%s   %s%s%s\n\n' "$(mark "${STATUS[$i]}")" "$B" "$id" "$X" "$D" "${DESCS[$i]}" "$X"
      if [ "${STATUS[$i]}" = ok ]; then printf 'now:        %s\n' "${WHERES[$i]//$HOME/~}"
      else printf 'now:        %s\nto do:      %s\n' "${REASONS[$i]}" "${FIXES[$i]}"; fi
      printf 'picking it: %s\n' "$(does "$id")"
      if [ "$id" = shell ]; then
        printf '\n%show your shell files load%s (no symlinks; the later one wins)\n' "$B" "$X"
        printf '  1 ~/.zshrc               this Mac'"'"'s file: should only hold the loader line\n'
        printf '  2 %s/shell/.zshrc   the repo file, same on every machine\n' "${DIR/#$HOME/~}"
        printf '  3 ~/.zshrc.local         this Mac only, loads last so it wins\n'
        for t in $SORT_FILES; do zsh "$DIR/shell/adopt.zsh" --list "$HOME/$t" 2>/dev/null; done
        [ "$SHELL_KEEP" = 1 ] && printf '\n%syou chose keep, so these stay where they are. picking shell asks again.%s\n' "$D" "$X"
      fi
    } > "$PV/$id"
  done
  for c in $(printf '%s\n' "${CLASSES[@]}" | awk '!seen[$0]++'); do
    { printf '%sall of %s:%s\n\n' "$B" "$c" "$X"
      for i in "${!IDS[@]}"; do [ "${CLASSES[$i]}" = "$c" ] && printf '  %s %-24s %s%s%s\n' "$(mark "${STATUS[$i]}")" "${IDS[$i]}" "$D" "${DESCS[$i]}" "$X"; done
    } > "$PV/group-$c"
  done
  pick_rows(){ local i grp=""
    printf 'fix\t%s★ fix what needs it%s       %s%s item(s), listed below%s\n' "$Y" "$X" "$D" "${#FIXABLE[@]}" "$X"
    printf 'all\t%s★ everything%s              %sre-apply all %s%s\n' "$Y" "$X" "$D" "${#IDS[@]}" "$X"
    for i in ${MISSING[@]+"${MISSING[@]}"}; do
      printf '%s\t%s %-26s %s%s%s\n' "${IDS[$i]}" "$(mark "${STATUS[$i]}")" "${IDS[$i]}" "$D" "${REASONS[$i]}" "$X"; done
    for i in "${!IDS[@]}"; do [ "${STATUS[$i]}" = ok ] || continue
      if [ "${CLASSES[$i]}" != "$grp" ]; then grp="${CLASSES[$i]}"; printf 'group-%s\t%s▸ %s%s\n' "$grp" "$B" "$grp" "$X"; fi
      printf '%s\t  %s %-24s %s%s%s\n' "${IDS[$i]}" "$(mark ok)" "${IDS[$i]}" "$D" "${DESCS[$i]}" "$X"
    done; return 0; }
  tput cnorm 2>/dev/null || true
  chosen="$(pick_rows | fzf -m --ansi --exact --scheme=history --delimiter='\t' --with-nth=2 --height=85% --layout=reverse \
      --prompt='pick > ' --header='enter: do the highlighted row · tab: mark several · shift+↑↓: scroll the panel · esc: back' \
      --preview "cat $PV/{1}" --preview-window=down,45%,wrap,border-top | cut -f1 || true)"
  [ "$UI_ON" = 1 ] && tput civis
  while IFS= read -r t; do case "$t" in
    "") ;;
    fix) SEL+=(${FIXABLE[@]+"${FIXABLE[@]}"}) ;;
    all) SEL+=("${!IDS[@]}") ;;
    group-*) for i in "${!IDS[@]}"; do [ "${CLASSES[$i]}" = "${t#group-}" ] && SEL+=("$i"); done ;;
    *) for i in "${!IDS[@]}"; do [ "${IDS[$i]}" = "$t" ] && SEL+=("$i"); done ;;
  esac; done <<< "$chosen"
  return 0; }

# step: pick. fix what needs it is already highlighted; the full list only when you ask
DO_UP=0
pick_step(){ local names="" i up="" o
  for i in ${FIXABLE[@]+"${FIXABLE[@]}"}; do names="$names · ${IDS[$i]}"; [ "${IDS[$i]}" = aws ] && names="$names (asks you)"; done
  names="${names# · }"
  [ "${#UP_N[@]}" -gt 0 ] || [ -n "$CLT_OLD" ] && up="Upgrade|${#UP_N[@]} newer versions; you tick which"
  while :; do SEL=(); DO_UP=0
    if [ "${#FIXABLE[@]}" -gt 0 ]; then
      if [ -n "$up" ]; then ui_menu "What should be installed or fixed?" 0 "Fix what needs it|$names" "Choose items…|opens the full list" "$up" "Nothing, I'm done|"
      else ui_menu "What should be installed or fixed?" 0 "Fix what needs it|$names" "Choose items…|opens the full list" "Nothing, I'm done|"; fi
      case "$UI_PICK" in 0) SEL=("${FIXABLE[@]}") ;; 1) pick_list ;; 2) [ -n "$up" ] && DO_UP=1 ;; esac
    else
      if [ -n "$up" ]; then ui_menu "Nothing needs fixing." 0 "$up" "Choose items…|re-apply anything from the full list" "Done|"
        case "$UI_PICK" in 0) DO_UP=1 ;; 1) pick_list; UI_PICK=1 ;; esac
      else ui_menu "Nothing needs fixing." 0 "Done|" "Choose items…|re-apply anything from the full list"
        [ "$UI_PICK" = 1 ] && pick_list; fi
    fi
    # an empty pick from the full list goes back to the menu
    [ "$UI_PICK" = 1 ] && [ "${#SEL[@]}" -eq 0 ] && { ui_frame 3; continue; }
    break
  done
  [ "${#SEL[@]}" -gt 0 ] && SEL=($(printf '%s\n' "${SEL[@]}" | awk '!seen[$0]++'))
  return 0; }

# one config item. its last line is what the install step shows; "note:" lines go in the receipt
cfg_step(){ local id="$1" t f old res n s d k bak
  case "$id" in
    shell)
      for f in .zprofile .zshrc; do t="$HOME/$f"
        if [ -L "$t" ] && [ "$(readlink "$t")" = "$DIR/shell/$f" ]; then
          rm "$t"; [ -f "$t.pre-dotfiles.bak" ] && mv "$t.pre-dotfiles.bak" "$t"
          echo "note: $t was a symlink to the repo; your own file is back"; fi
        # not sorted on screen (--all, or no terminal): merge with the safe choices
        if { [ "$SHELL_ASKED" = 0 ] || [ "$SHELL_KEEP" = 1 ]; } && [ -s "$t" ] && command -v zsh >/dev/null; then
          res="$(zsh "$DIR/shell/adopt.zsh" --apply "$t" --no-check 2>/dev/null || true)"
          n="$(printf '%s\n' "$res" | awk -F'\t' '$1 == "undo" { print $2 }')"
          [ -n "$n" ] && echo "note: ~/$f sorted (lines only you had moved to ~/$f.local). undo: $n"
        fi
        put_block "$t" "$MARK_START" "$MARK_END" "[ -f \"$DIR/shell/$f\" ] && source \"$DIR/shell/$f\""
      done
      echo "loader in ~/.zprofile and ~/.zshrc" ;;
    git)
      GC="$HOME/.gitconfig"; [ -L "$GC" ] && GC="$(perl -MCwd -e 'print Cwd::realpath(shift)' "$GC")"; touch "$GC"
      # repoint an include left by another checkout of this repo (a worktree, an old clone), else add one
      old="$(git config --file "$GC" --get-all include.path 2>/dev/null | while IFS= read -r p; do
        [ "$p" != "$DIR/git/.gitconfig" ] && [ "${p%/git/.gitconfig}/git/.gitconfig" = "$p" ] &&
          [ -f "${p%/git/.gitconfig}/install.sh" ] && echo "$p"; done | head -1)"
      if grep -qsF "$DIR/git/.gitconfig" "$GC"; then :
      elif [ -n "$old" ]; then git config --file "$GC" --replace-all include.path "$DIR/git/.gitconfig" "^$old\$"
      else git config --file "$GC" --add include.path "$DIR/git/.gitconfig"; fi
      [ -z "$(git config --get user.email 2>/dev/null || true)" ] && \
        echo "note: set your git identity: git config --global user.name '...' && git config --global user.email '...'"
      command -v gh >/dev/null && ! gh auth status >/dev/null 2>&1 && echo "note: log in to github (browser, token goes in keychain): gh auth login"
      echo "~/.gitconfig includes git/.gitconfig" ;;
    ghostty-theme) [ -x "$DIR/ghostty/install.sh" ] && "$DIR/ghostty/install.sh"
      echo "$(ls "$DIR/ghostty/themes" | wc -l | tr -d ' ') themes + gtheme copied" ;;
    ghostty-tabs)
      mkdir -p "$(dirname "$GHOSTTY_CONFIG")"
      put_block "$GHOSTTY_CONFIG" "$TABS_START" "$TABS_END" "config-file = ?$DIR/ghostty/tabs.conf"
      echo "note: new ghostty tabs pick up the titles; quit and reopen ghostty for the tab bar style"
      echo "tabs block in ghostty's config" ;;
    nvim)
      t="$HOME/.config/nvim"; mkdir -p "$HOME/.config"
      if [ -L "$t" ] && [ -f "$(readlink "$t")/lua/dotfiles/helpers.lua" ]; then rm "$t"   # a link to another checkout of this repo
      elif [ -e "$t" ] || [ -L "$t" ]; then mv "$t" "$t.bak-$STAMP"; echo "note: your old ~/.config/nvim is kept as ~/.config/nvim.bak-$STAMP"; fi
      ln -s "$DIR/nvim" "$t"
      if command -v nvim >/dev/null; then
        nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || true
        echo "note: the first nvim start installs language tools in the background (a minute or two)"
      else echo "note: nvim isn't installed yet: ./install.sh --only neovim"; fi
      echo "~/.config/nvim linked, plugins pinned" ;;
    skills)
      n=0; k=""; bak="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/skills-bak-$STAMP"
      for t in "$HOME/.agents/skills" "$HOME/.claude/skills"; do mkdir -p "$t"
        for s in "$DIR"/agents/skills/*/; do f="$(basename "$s")"; d="$t/$f"
          if [ -d "$d" ] && diff -rq -x __pycache__ -x .dotfiles "$s" "$d" >/dev/null 2>&1; then touch "$d/.dotfiles"; continue; fi
          if [ -d "$d" ]; then
            # a copy you changed: only replaced when you said so, and saved first (outside the skill
            # folders, so the tools don't load the old copy as a second skill)
            case " $SKILL_OVER " in
              *" $f "*) mkdir -p "$bak/${t##*/.}"; cp -R "$d" "$bak/${t##*/.}/$f" ;;
              *) case " $k " in *" $f "*) ;; *) k="$k $f" ;; esac; continue ;;
            esac
          fi
          rsync -a --delete --exclude __pycache__ --exclude .dotfiles "$s" "$d/"; touch "$d/.dotfiles"; n=$((n + 1))
        done
      done
      [ -n "$k" ] && echo "note: kept yours:$k"
      [ -d "$bak" ] && echo "note: the skills you replaced are saved in ${bak/#$HOME/~}"
      for s in "$DIR"/agents/skills/*/; do d="$(basename "$s")"
        [ -f "$HOME/.claude/commands/$d.md" ] && echo "note: ~/.claude/commands/$d.md is an older slash command with the same name as a skill"
      done
      if [ "$n" = 0 ]; then echo "nothing new to copy"; else echo "$n skill copies updated"; fi ;;
    macos)   bash "$DIR/macos/defaults.sh"; echo "settings applied" ;;
    claude)
      if command -v claude >/dev/null; then echo "already installed: $(command -v claude)"
      else curl -fsSL https://claude.ai/install.sh | bash; echo "installed"; fi ;;
    aws)
      if [ -t 0 ] && [ -t 1 ]; then "$DIR/bin/awssetup" || { echo "note: awssetup didn't finish; run it again any time: awssetup"; return 1; }
      else echo "note: aws needs a terminal (it asks questions and opens a browser). run later: awssetup"; fi
      echo "profiles written" ;;
  esac
  return 0; }

# skills you changed (or that came from another checkout) are only replaced if you say so
SKILL_OVER=""
skills_ask(){ local s f t o w names="" where="" i
  local -a chg=()
  for s in "$DIR"/agents/skills/*/; do f="$(basename "$s")"
    for t in "$HOME/.agents/skills" "$HOME/.claude/skills"; do
      [ -d "$t/$f" ] && ! diff -rq -x __pycache__ -x .dotfiles "$s" "$t/$f" >/dev/null 2>&1 && { chg+=("$f"); break; }; done; done
  [ "${#chg[@]}" -gt 0 ] || return 0
  # where yours came from: another checkout of this repo, or edited after install
  for f in "${chg[@]}"; do names="$names, $f"
    for o in $(git -C "$DIR" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p'); do
      [ "$o" != "$DIR" ] && diff -rq -x __pycache__ -x .dotfiles "$o/agents/skills/$f" "$HOME/.claude/skills/$f" >/dev/null 2>&1 && where="${o/#$HOME/~}"; done; done
  [ -n "$where" ] && w="yours came from $where" || w="yours were changed after they were installed"
  ui_menu "${#chg[@]} installed skills differ from this folder's copies: ${names#, }"$'\n'"$w" 0 \
    "Keep all of mine|recommended; only missing skills get copied" "Overwrite all|with this folder's copies; yours saved to ~/.cache/dotfiles" "Choose each one|"
  case "$UI_PICK" in
    1) SKILL_OVER="${chg[*]}" ;;
    2) for f in "${chg[@]}"; do
         ui_menu "$f"$'\n'"$(diff -r -x __pycache__ -x .dotfiles "$HOME/.claude/skills/$f" "$DIR/agents/skills/$f" 2>/dev/null | grep -c '^[<>]' || true) lines differ" 0 "Keep mine|$(sed -n 's/^description: *//p' "$HOME/.claude/skills/$f/SKILL.md" 2>/dev/null | head -1)" \
           "Use this folder's|$(sed -n 's/^description: *//p' "$DIR/agents/skills/$f/SKILL.md" | head -1)"
         [ "$UI_PICK" = 1 ] && SKILL_OVER="$SKILL_OVER $f"; done ;;
  esac
  return 0; }

# step: install. one line per item with a spinner; everything they print goes to a log
install_step(){ local i id st pid tmp line LOG ok="" bad="" t
  local -a pkg=() cfg=() talk=()
  LOG="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/install-$STAMP.log"; mkdir -p "$(dirname "$LOG")"; : > "$LOG"
  for i in ${SEL[@]+"${SEL[@]}"}; do
    if [ "${KINDS[$i]}" = config ]; then
      # aws asks questions in the terminal, so it runs last, in the open
      if [ "${IDS[$i]}" = aws ]; then talk+=("$i"); else cfg+=("$i"); fi
    else pkg+=("$i"); fi; done
  for i in ${cfg[@]+"${cfg[@]}"}; do [ "${IDS[$i]}" = skills ] && skills_ask; done
  for i in ${pkg[@]+"${pkg[@]}"} ${cfg[@]+"${cfg[@]}"} ${talk[@]+"${talk[@]}"}; do row_add "${IDS[$i]}" "queued"; done
  [ "$UI_TTY" = 1 ] || printf '\n%sinstalling%s  %sfull output: %s%s\n' "$B" "$X" "$D" "${LOG/#$HOME/~}" "$X"
  rows_draw
  if [ "${#pkg[@]}" -gt 0 ]; then
    tmp="$(mktemp)"; grep -E '^tap ' "$DIR/Brewfile" >> "$tmp" || true
    for i in "${pkg[@]}"; do   # copy the Brewfile line as-is so options like trusted: true survive
      if [ "${KINDS[$i]}" = cask ] && [[ "${SPECS[$i]}" != *args:* ]]; then printf '%s, args: { adopt: true }\n' "${SPECS[$i]}" >> "$tmp"
      else printf '%s\n' "${SPECS[$i]}" >> "$tmp"; fi
    done
    brew bundle --file="$tmp" >> "$LOG" 2>&1 & pid=$!
    while kill -0 "$pid" 2>/dev/null; do
      for i in "${pkg[@]}"; do id="${IDS[$i]}"
        line="$(grep -E "^(Installing|Using|Upgrading) (.*/)?$id( |$)" "$LOG" | tail -1 || true)"
        case "$line" in Using*) row_set "$id" ok "already installed" ;; Installing*|Upgrading*) row_set "$id" run "${line%% *}…" ;; esac
      done
      rows_draw; sleep 0.15
    done
    if wait "$pid"; then st=0; else st=1; fi
    for i in "${pkg[@]}"; do id="${IDS[$i]}"
      if grep -qE "(Installing|Upgrading) (.*/)?$id has failed" "$LOG"; then row_set "$id" fail "failed, see the log"
      elif grep -qE "^Using (.*/)?$id( |$)" "$LOG"; then row_set "$id" ok "already installed"
      elif [ "$st" = 0 ]; then row_set "$id" ok "installed"
      else row_set "$id" fail "brew bundle failed, see the log"; fi
      row_print "$id"
    done
    rm -f "$tmp"; rows_draw
  fi
  for i in ${cfg[@]+"${cfg[@]}"}; do id="${IDS[$i]}"; row_set "$id" run "working…"
    ( cfg_step "$id" ) > "$LOG.one" 2>&1 & pid=$!
    while kill -0 "$pid" 2>/dev/null; do rows_draw; sleep 0.15; done
    if wait "$pid"; then st=ok; else st=fail; fi
    t="$(grep -v '^note: ' "$LOG.one" | grep -v '^[[:space:]]*$' | tail -1 | sed "s|$HOME|~|g")"
    [ "$st" = fail ] && t="failed, see the log"
    row_set "$id" "$st" "${t:-done}"; row_print "$id"
    while IFS= read -r line; do RECEIPT+=("  ${D}${line/#note: /note: }${X}"); done < <(grep '^note: ' "$LOG.one" | sed "s|$HOME|~|g")
    { echo "== $id"; cat "$LOG.one"; } >> "$LOG"; rm -f "$LOG.one"; rows_draw
  done
  for i in ${talk[@]+"${talk[@]}"}; do id="${IDS[$i]}"; row_set "$id" you "needs you, below"; rows_draw; UI_ROWS_DRAWN=0
    tput cnorm 2>/dev/null || true; echo
    if cfg_step "$id"; then row_set "$id" ok "done"; else row_set "$id" fail "didn't finish"; fi
    [ "$UI_ON" = 1 ] && tput civis
  done
  for i in "${!ROW_N[@]}"; do case "${ROW_S[$i]}" in ok) ok="$ok, ${ROW_N[$i]}" ;; fail) bad="$bad, ${ROW_N[$i]}" ;; esac; done
  [ -n "$ok" ] && RECEIPT+=("  ${G}✓${X} done        ${ok#, }")
  [ -n "$bad" ] && RECEIPT+=("  ${R}✗${X} failed      ${bad#, }  ${D}(log: ${LOG/#$HOME/~})${X}")
  return 0; }

# fix = missing, set up from another folder, or shell lines left to sort. "differs" means your
# own edits, so those only change when picked by name; shell lines you chose to keep stay out too
fixable(){ local i; FIXABLE=()
  for i in ${MISSING[@]+"${MISSING[@]}"}; do case "${STATUS[$i]}" in
    differs) ;; sort) [ "$SHELL_KEEP" = 1 ] || FIXABLE+=("$i") ;; *) FIXABLE+=("$i") ;; esac; done
  return 0; }
receipt_head(){ RECEIPT=("" "${B}dotfiles${X}  ${D}${UI_HEAD}${X}" ${RECEIPT[@]+"${RECEIPT[@]}"}); }
receipt_tail(){ [ "${#SEL[@]}" -gt 0 ] || [ "$SHELL_WROTE" = 1 ] || [ "$DO_UP" = 1 ] || RECEIPT+=("  ${D}· nothing changed${X}")
  { [ "$SHELL_WROTE" = 1 ] || [[ " ${SEL[*]:-} " == *" $SHELL_I "* ]]; } && RECEIPT+=("  open a new terminal (or run: ${B}exec zsh${X}) to pick up the shell changes")
  receipt_head; RECEIPT+=(""); }
for i in "${!IDS[@]}"; do [ "${IDS[$i]}" = shell ] && SHELL_I=$i; done
SEL=(); trap 'ui_end' EXIT

case "$MODE" in
  check) check_screen
    if [ -n "${DOT_STATE:-}" ]; then fixable; printf 'fix=%s\nup=%s\nclt=%s\n' "${#FIXABLE[@]}" "${#UP_N[@]}" "$CLT_OLD" > "$DOT_STATE"; fi
    exit 0 ;;
  all)
    check_screen; fixable
    [ "${#FIXABLE[@]}" -eq 0 ] && { printf '%snothing to fix.%s\n' "$G" "$X"; exit 0; }
    SEL=("${FIXABLE[@]}"); install_step; receipt_tail ;;
  only)
    for i in "${!IDS[@]}"; do [[ "$ONLY" == *",${IDS[$i]},"* ]] && SEL+=("$i"); done
    [ "${#SEL[@]}" -eq 0 ] && { echo "nothing matches --only ${ONLY//,/ }"; exit 2; }
    if [[ "$ONLY" == *",shell,"* ]] && [ "$UI_TTY" = 1 ] && [ "$SORT_N" -gt 0 ]; then
      UI_STEPS=(shell install); ui_start; shell_step 1; ui_next; ui_frame 2
    else UI_STEPS=(install); fi
    install_step; [ "$UI_ON" = 1 ] && ui_next "enter: done"; receipt_tail ;;
  pick)
    if [ "$UI_TTY" != 1 ]; then check_screen; printf 'not a terminal - re-run with %s--all%s to fix what needs it.\n' "$B" "$X"; exit 0; fi
    UI_STEPS=(check shell pick install)
    case "${STATUS[$SHELL_I]}" in sort|missing) [ "$SORT_N" -gt 0 ] || UI_SKIP[1]="nothing to sort" ;;
                                  elsewhere) UI_SKIP[1]="from another folder" ;; *) UI_SKIP[1]="nothing to sort" ;; esac
    ui_start
    ui_frame 1; check_screen; ui_next "enter: next step · q: quit"
    if [ -z "${UI_SKIP[1]:-}" ]; then shell_step 2; recheck "$SHELL_I"; ui_next "enter: next step · q: quit"; fi
    fixable; ui_frame 3; pick_step
    if [ "${#SEL[@]}" -gt 0 ]; then ui_frame 4; install_step; ui_next "enter: done"
    elif [ "$DO_UP" = 1 ]; then ui_frame 4; upgrade_flow; ui_next "enter: done"; fi
    receipt_tail ;;
esac

# ui.sh - the screens install.sh and dot draw: their own screen (like vim), a step bar,
# ◆ arrow-key menus, and rows with spinners. sourced, not run. works in bash 3.2 (macOS).
# without a terminal every question takes its default and output is plain lines.

export LC_CTYPE="${LC_CTYPE:-en_US.UTF-8}"   # so ${#x} counts characters, not bytes
UI_TTY=0; [ -t 0 ] && [ -t 1 ] && UI_TTY=1
if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; C=$'\033[36m'; D=$'\033[2m'; B=$'\033[1m'; X=$'\033[0m'
else G= R= Y= C= D= B= X=; fi
UI_ON=0; UI_DONE=0; UI_HEAD=""; UI_CLEAN=""; RECEIPT=(); UI_STEPS=(); UI_SKIP=()

ui_cols(){ local c; c="$(tput cols 2>/dev/null || echo 80)"; [ "${c:-0}" -gt 20 ] 2>/dev/null || c=80; echo "$c"; }
UI_W="$(ui_cols)"

# pad TEXT WIDTH / cut TEXT WIDTH, by visible characters (colors not allowed inside)
pad(){ local n=$(( $2 - ${#1} )); [ "$n" -gt 0 ] || n=0; printf '%s%*s' "$1" "$n" ''; }
cut_to(){ if [ "${#1}" -gt "$2" ]; then printf '%s…' "${1:0:$(($2 - 1))}"; else printf '%s' "$1"; fi; }
rule(){ local w=$(( UI_W < 76 ? UI_W - 2 : 74 )) l=""; while [ "${#l}" -lt "$w" ]; do l="${l}─"; done; printf '%s%s%s\n' "$D" "$l" "$X"; }

# its own screen: what was in the terminal comes back at the end, plus the receipt
ui_start(){ [ "$UI_TTY" = 1 ] || return 0; tput smcup; tput civis; UI_ON=1
  trap 'ui_end' EXIT; trap 'ui_end; exit 130' INT TERM; }
ui_end(){ local l
  [ "$UI_DONE" = 1 ] && return 0; UI_DONE=1
  if [ "$UI_ON" = 1 ]; then tput cnorm; tput rmcup; UI_ON=0; fi
  [ -n "$UI_CLEAN" ] && rm -rf $UI_CLEAN
  [ "${#RECEIPT[@]}" -gt 0 ] && for l in "${RECEIPT[@]}"; do printf '%s\n' "$l"; done
  return 0; }
ui_quit(){ RECEIPT+=("  ${D}stopped here; nothing after this point was changed.${X}" "")
  type receipt_head >/dev/null 2>&1 && receipt_head; exit 1; }

# the frame on top of every step: header, ✓ done ━━ ● now ━━ ○ next, a rule
ui_frame(){ local cur="$1" i s bar=""
  if [ "$UI_ON" != 1 ]; then printf '\n%s%s%s\n' "$B" "${UI_STEPS[$((cur - 1))]:-}" "$X"; return 0; fi
  printf '\033[H\033[2J'
  printf '%sdotfiles%s  %s%s%s\n ' "$B" "$X" "$D" "$UI_HEAD" "$X"
  for i in "${!UI_STEPS[@]}"; do s="${UI_STEPS[$i]}"
    [ "$i" -gt 0 ] && bar="$bar ${D}━━${X} "
    if [ "$i" -lt "$((cur - 1))" ]; then bar="$bar${G}✓${X} $s${UI_SKIP[$i]:+ ${D}(${UI_SKIP[$i]})${X}}"
    elif [ "$i" = "$((cur - 1))" ]; then bar="$bar${C}●${X} ${B}$s${X}"
    else bar="$bar${D}○ $s${X}"; fi
  done
  printf '%s\n' "$bar"; rule; echo; }

# ui_menu QUESTION DEFAULT "label|detail"... -> UI_PICK (0-based). ↑↓ or j/k, a number, enter.
# q or esc stops the whole run. answered menus shrink to one ◇ line
# a second line in QUESTION (after a newline) shows dim under it, and goes once it's answered
ui_menu(){ local q="${1%%$'\n'*}" sub="" sel="$2" n i k k2 lw=0 l d w h
  [ "$q" != "$1" ] && sub="${1#*$'\n'}"; shift 2; n=$#
  local -a lab det; for i in "$@"; do lab+=("${i%%|*}"); d="${i#*|}"; [ "$d" = "$i" ] && d=""; det+=("$d"); done
  for l in "${lab[@]}"; do if [ "${#l}" -gt "$lw" ]; then lw=${#l}; fi; done
  if [ "$UI_TTY" != 1 ]; then UI_PICK=$sel; return 0; fi
  w=$(( UI_W - lw - 10 )); h=$((n + 2)); [ -n "$sub" ] && h=$((n + 3))
  while :; do
    printf '%s◆%s  %s%s%s\n' "$C" "$X" "$B" "$q" "$X"
    [ -n "$sub" ] && printf '%s│%s  %s%s%s\n' "$C" "$X" "$D" "$(cut_to "$sub" $((UI_W - 6)))" "$X"
    for i in "${!lab[@]}"; do
      if [ "$i" = "$sel" ]; then printf '%s│%s  %s●%s %s  %s%s%s\n' "$C" "$X" "$G" "$X" "$(pad "${lab[$i]}" "$lw")" "$D" "$(cut_to "${det[$i]}" "$w")" "$X"
      else printf '%s│%s  %s○ %s  %s%s\n' "$C" "$X" "$D" "$(pad "${lab[$i]}" "$lw")" "$(cut_to "${det[$i]}" "$w")" "$X"; fi
    done
    printf '%s└%s  %s↑↓ move · enter pick · q quit%s\n' "$C" "$X" "$D" "$X"
    IFS= read -rsn1 k </dev/tty || k=q
    case "$k" in
      $'\033') IFS= read -rsn2 -t 1 k2 </dev/tty || k2=""
               case "$k2" in '[A') sel=$(( (sel + n - 1) % n )) ;; '[B') sel=$(( (sel + 1) % n )) ;; '') ui_quit ;; esac ;;
      k|K) sel=$(( (sel + n - 1) % n )) ;; j|J) sel=$(( (sel + 1) % n )) ;;
      [1-9]) [ "$k" -le "$n" ] && sel=$((k - 1)) ;;
      q|Q) ui_quit ;;
      "") printf '\033[%dA\r\033[J' "$h"; break ;;
    esac
    printf '\033[%dA\r\033[J' "$h"
  done
  printf '%s◇%s  %s  %s%s%s\n%s│%s\n' "$G" "$X" "$q" "$D" "${lab[$sel]}" "$X" "$D" "$X"
  UI_PICK=$sel; }

# ui_ask QUESTION -> UI_TEXT: a line of text (empty is fine)
ui_ask(){ UI_TEXT=""; [ "$UI_TTY" = 1 ] || return 0
  printf '%s◆%s  %s%s%s  %s(enter to skip)%s\n%s│%s  ' "$C" "$X" "$B" "$1" "$X" "$D" "$X" "$C" "$X"
  tput cnorm; IFS= read -r UI_TEXT </dev/tty || UI_TEXT=""; [ "$UI_ON" = 1 ] && tput civis; printf '%s│%s\n' "$D" "$X"; }

# ui_next HINT - wait for enter (q stops)
ui_next(){ local k; [ "$UI_TTY" = 1 ] || return 0
  printf '\n'; rule; printf ' %s%s%s' "$D" "${1:-enter: next · q: quit}" "$X"
  while IFS= read -rsn1 k </dev/tty; do case "$k" in "") break ;; q|Q|$'\033') ui_quit ;; esac; done; echo; }

# rows with live status, for the install step. ROW_N name, ROW_S queued|run|ok|fail|you|skip, ROW_T text
ROW_N=(); ROW_S=(); ROW_T=(); UI_ROWS_DRAWN=0; UI_SPIN=0; ROW_HEAD=""   # ROW_HEAD: a status line above the rows
row_add(){ ROW_N+=("$1"); ROW_S+=(queued); ROW_T+=("$2"); }
row_set(){ local i; for i in "${!ROW_N[@]}"; do if [ "${ROW_N[$i]}" = "$1" ]; then ROW_S[$i]="$2"; [ -z "${3:-}" ] || ROW_T[$i]="$3"; fi; done; return 0; }
rows_draw(){ local i m f=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏) w=$(( UI_W - 22 ))
  [ "$UI_TTY" = 1 ] || return 0
  [ "$UI_ROWS_DRAWN" -gt 0 ] && printf '\033[%dA\r\033[J' "$UI_ROWS_DRAWN"
  UI_SPIN=$(( (UI_SPIN + 1) % 10 ))
  [ -n "$ROW_HEAD" ] && printf '  %s%s %s%s\n' "$C" "${f[$UI_SPIN]}" "$(cut_to "$ROW_HEAD" $((UI_W - 6)))" "$X"
  for i in "${!ROW_N[@]}"; do
    case "${ROW_S[$i]}" in
      ok) m="${G}✓${X}" ;; fail) m="${R}✗${X}" ;; run) m="${C}${f[$UI_SPIN]}${X}" ;; you) m="${Y}◆${X}" ;; skip) m="${D}·${X}" ;; *) m="${D}○${X}" ;; esac
    printf '  %s %s %s%s%s\n' "$m" "$(pad "$(cut_to "${ROW_N[$i]}" 16)" 16)" "$D" "$(cut_to "${ROW_T[$i]}" "$w")" "$X"
  done
  UI_ROWS_DRAWN=${#ROW_N[@]}; [ -n "$ROW_HEAD" ] && UI_ROWS_DRAWN=$((UI_ROWS_DRAWN + 1)); return 0; }
# without a terminal: one plain line per row once it's finished
row_print(){ local i; [ "$UI_TTY" = 1 ] && return 0
  for i in "${!ROW_N[@]}"; do [ "${ROW_N[$i]}" = "$1" ] || continue
    case "${ROW_S[$i]}" in ok) printf '  ✓ %-16s %s\n' "$1" "${ROW_T[$i]}" ;; fail) printf '  ✗ %-16s %s\n' "$1" "${ROW_T[$i]}" ;; esac; done; return 0; }

# ui_checklist QUESTION "label|detail|1 or 0"... -> UI_TICKS (one 1/0 per item, space separated).
# ↑↓ move, space ticks, a all, n none, enter goes, q stops. long lists scroll
ui_checklist(){ local q="$1" n i k k2 cur=0 top=0 view lw=0 l d w h on cnt
  shift; n=$#
  local -a lab det tick
  for i in "$@"; do l="${i%%|*}"; d="${i#*|}"; lab+=("$l"); det+=("${d%|*}"); tick+=("${i##*|}"); done
  for l in "${lab[@]}"; do if [ "${#l}" -gt "$lw" ]; then lw=${#l}; fi; done
  if [ "$UI_TTY" != 1 ]; then UI_TICKS="${tick[*]}"; return 0; fi
  view=$(( $(tput lines 2>/dev/null || echo 24) - 14 )); [ "$view" -lt 6 ] && view=6; [ "$view" -gt "$n" ] && view=$n
  w=$(( UI_W - lw - 12 ))
  while :; do
    [ "$cur" -lt "$top" ] && top=$cur; [ "$cur" -ge $((top + view)) ] && top=$((cur - view + 1))
    cnt=0; for i in "${tick[@]}"; do [ "$i" = 1 ] && cnt=$((cnt + 1)); done
    printf '%s◆%s  %s%s%s  %sspace ticks · a all · n none%s\n' "$C" "$X" "$B" "$q" "$X" "$D" "$X"; h=1
    if [ "$top" -gt 0 ]; then printf '%s│%s  %s↑ %s more%s\n' "$C" "$X" "$D" "$top" "$X"; else printf '%s│%s\n' "$C" "$X"; fi; h=$((h + 1))
    for ((i = top; i < top + view; i++)); do
      if [ "${tick[$i]}" = 1 ]; then on="${G}◼${X}"; else on="${D}◻${X}"; fi
      if [ "$i" = "$cur" ]; then printf '%s│%s %s›%s%s %s%s%s  %s%s%s\n' "$C" "$X" "$C" "$X" "$on" "$B" "$(pad "${lab[$i]}" "$lw")" "$X" "$D" "$(cut_to "${det[$i]}" "$w")" "$X"
      else printf '%s│%s  %s %s  %s%s%s\n' "$C" "$X" "$on" "$(pad "${lab[$i]}" "$lw")" "$D" "$(cut_to "${det[$i]}" "$w")" "$X"; fi
      h=$((h + 1))
    done
    if [ $((top + view)) -lt "$n" ]; then printf '%s│%s  %s↓ %s more%s\n' "$C" "$X" "$D" $((n - top - view)) "$X"; else printf '%s│%s\n' "$C" "$X"; fi
    printf '%s└%s  %s%s ticked · enter goes · q quit%s\n' "$C" "$X" "$D" "$cnt" "$X"; h=$((h + 2))
    IFS= read -rsn1 k </dev/tty || k=q
    case "$k" in
      $'\033') IFS= read -rsn2 -t 1 k2 </dev/tty || k2=""
               case "$k2" in '[A') [ "$cur" -gt 0 ] && cur=$((cur - 1)) ;; '[B') [ "$cur" -lt $((n - 1)) ] && cur=$((cur + 1)) ;; '') ui_quit ;; esac ;;
      k|K) [ "$cur" -gt 0 ] && cur=$((cur - 1)) ;; j|J) [ "$cur" -lt $((n - 1)) ] && cur=$((cur + 1)) ;;
      " ") if [ "${tick[$cur]}" = 1 ]; then tick[$cur]=0; else tick[$cur]=1; fi ;;
      a|A) for i in "${!tick[@]}"; do tick[$i]=1; done ;;
      n|N) for i in "${!tick[@]}"; do tick[$i]=0; done ;;
      q|Q) ui_quit ;;
      "") printf '\033[%dA\r\033[J' "$h"; break ;;
    esac
    printf '\033[%dA\r\033[J' "$h"
  done
  printf '%s◇%s  %s  %s%s ticked%s\n%s│%s\n' "$G" "$X" "$q" "$D" "$cnt" "$X" "$D" "$X"
  UI_TICKS="${tick[*]}"; }

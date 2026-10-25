# upgrade.sh - newer versions of what you installed, for install.sh's check and `dot upgrade`.
# sourced, not run; needs lib/ui.sh and $DIR. it reads brew's own version info as is (brew
# refreshes it about once a day), so a check costs about a second and never hits the network.

UP_N=(); UP_FULL=(); UP_FROM=(); UP_TO=(); UP_KIND=(); UP_NOTE=(); UP_TICK=(); UP_SRC=()
CLT_OLD=""; UP_AGE=""; UP_BIG=0; UP_TMP=""

# start the slow part (brew outdated) in the background; upgrade_scan picks it up
upgrade_start(){ command -v brew >/dev/null && command -v jq >/dev/null || return 0
  UP_TMP="$(mktemp)"; UI_CLEAN="$UI_CLEAN $UP_TMP"
  HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --json=v2 > "$UP_TMP" 2>/dev/null &
  UP_PID=$!; return 0; }

# tools where a minor version bump can still bite, and why
careful(){ case "$1" in
  terraform) echo "state written by a newer terraform can't be read by an older one; repos often pin a version" ;;
  kubernetes-cli) echo "kubectl should stay within one minor version of your clusters" ;;
esac; }

# vmajor VERSION -> first number; vminor VERSION -> second number (0 when there's none)
vmajor(){ echo "$1" | awk -F. '{ print $1 + 0 }'; }
vminor(){ echo "$1" | awk -F. '{ print $2 + 0 }'; }

upgrade_scan(){ local k full from to s src a1 a2 b1 b2 note tick leaves bf m v now
  UP_N=(); UP_FULL=(); UP_FROM=(); UP_TO=(); UP_KIND=(); UP_NOTE=(); UP_TICK=(); UP_SRC=(); UP_BIG=0; CLT_OLD=""; UP_AGE=""
  command -v brew >/dev/null && command -v jq >/dev/null || return 0
  [ -n "$UP_TMP" ] || upgrade_start
  wait "$UP_PID" 2>/dev/null || true
  # only what you asked for (or the Brewfile lists): dependencies upgrade along with whatever needs them
  leaves=" $( { brew list --formula --installed-on-request || brew leaves --installed-on-request; brew list --cask -1; } 2>/dev/null | sed 's|.*/||' | tr '\n' ' ' || true) "
  bf=" $(grep -oE '^(brew|cask) "[^"]+"' "$DIR/Brewfile" | sed 's/.*"\(.*\)"/\1/; s|.*/||' | tr '\n' ' ') "
  while IFS=$'\t' read -r k full from to; do
    [ -n "$full" ] || continue; s="${full##*/}"
    case "$bf" in *" $s "*) src=brewfile ;; *) src=yours; case "$leaves" in *" $s "*) ;; *) continue ;; esac ;; esac
    a1=$(vmajor "$from"); a2=$(vmajor "$to"); b1=$(vminor "$from"); b2=$(vminor "$to"); note=""; tick=1
    # left unticked: a new major version, or a minor bump of a tool where versions have to match
    if [ "$a1" != "$a2" ] && [ "$a1" -ge 1 ] 2>/dev/null; then note="major version: can break things"; tick=0
    elif [ -n "$(careful "$s")" ] && [ "$b1" != "$b2" ]; then note="$(careful "$s")"; tick=0; fi
    [ "$tick" = 0 ] && UP_BIG=$((UP_BIG + 1))
    [ "$src" = yours ] && note="${note:+$note · }not in the Brewfile"
    UP_N+=("$s"); UP_FULL+=("$full"); UP_FROM+=("$from"); UP_TO+=("$to"); UP_KIND+=("$k"); UP_NOTE+=("$note"); UP_TICK+=("$tick"); UP_SRC+=("$src")
  done < <(jq -r '(.formulae[] | select(.pinned | not) | ["formula", .name, (.installed_versions | last), .current_version]),
                  (.casks[] | ["cask", .name, (.installed_versions | last), .current_version]) | @tsv' "$UP_TMP" 2>/dev/null \
           | awk -F'\t' -v bf="$bf" '
               { n = $2; sub(/.*\//, "", n); print (index(" " bf " ", " " n " ") ? 0 : 1) "\t" n "\t" $0 }' | sort | cut -f3-)
  # the command line tools: brew won't install anything that builds on this Mac while they're too old
  if [ "$(uname -s)" = Darwin ]; then
    v="$(pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null | awk '/^version/ { print $2 }' || true)"
    m="$(sw_vers -productVersion | cut -d. -f1)"
    [ -n "$v" ] && [ "${v%%.*}" -lt "$m" ] 2>/dev/null && CLT_OLD="$(echo "$v" | cut -d. -f1-2)"
  fi
  # how old brew's version info is
  now=$(date +%s); v="$(stat -f %m "$(brew --repository)/.git/FETCH_HEAD" 2>/dev/null || stat -f %m "$(brew --cache)/api" 2>/dev/null || echo "$now")"
  v=$(( (now - v) / 60 ))
  if [ "$v" -lt 2 ]; then UP_AGE="a minute"; elif [ "$v" -lt 60 ]; then UP_AGE="$v min"; elif [ "$v" -lt 2880 ]; then UP_AGE="$((v / 60)) h"; else UP_AGE="$((v / 1440)) days"; fi
  return 0; }

# the newest command line tools apple offers this mac -> CLT_LABEL, CLT_NEW. homebrew's own
# install method: while the placeholder file exists, softwareupdate lists them
clt_find(){ local ph=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  CLT_LABEL=""; CLT_NEW=""; touch "$ph"
  IFS=$'\t' read -r CLT_NEW CLT_LABEL < <(softwareupdate --list 2>/dev/null | awk '
    /^\* Label: .*Command Line Tools/ { l = $0; sub(/^\* Label: /, "", l); next }
    l != "" && /Version:/ { v = $0; sub(/.*Version: /, "", v); sub(/,.*/, "", v); print v "\t" l; l = "" }' |
    sort -t. -k1,1n -k2,2n | tail -1) || true
  rm -f "$ph"; return 0; }

# update the command line tools: only that package, never a macos update (those restart)
clt_update(){ local v m
  printf '%s│%s  %sasking Apple for the newest command line tools…%s' "$D" "$X" "$D" "$X"; clt_find; printf '\r\033[K'
  tput cnorm 2>/dev/null || true
  if [ -n "$CLT_LABEL" ]; then
    ui_menu "Install $CLT_LABEL?"$'\n'"only the tools: no macOS update, no restart, open apps stay open. about 900 MB" 0 \
      "Install now|asks for your Mac password, takes a few minutes" "Skip for now|"
    [ "$UI_PICK" = 0 ] || return 0
    if ! sudo softwareupdate --install "$CLT_LABEL"; then printf '%s✗%s  the install didn'"'"'t finish\n' "$R" "$X"; fi
  else
    ui_menu "Apple's update tool doesn't offer them right now"$'\n'"Homebrew's fallback: remove the old tools, then reinstall them from Apple's installer window" 0 \
      "Reinstall them|asks for your Mac password, then a small installer window opens" "Open Software Update|do it there yourself" "Skip for now|"
    case "$UI_PICK" in
      0) if sudo rm -rf /Library/Developer/CommandLineTools && sudo xcode-select --install; then
           ui_next "click Install in the window that opened; press enter here when it says it's done"
         else printf '%s✗%s  that didn'"'"'t work; try Software Update instead\n' "$R" "$X"; fi ;;
      1) open "x-apple.systempreferences:com.apple.Software-Update-Settings.extension" 2>/dev/null || true; return 0 ;;
      *) return 0 ;;
    esac
  fi
  [ "$UI_ON" = 1 ] && tput civis
  # did it take?
  v="$(pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null | awk '/^version/ { print $2 }' || true)"
  m="$(sw_vers -productVersion | cut -d. -f1)"
  if [ -n "$v" ] && [ "${v%%.*}" -ge "$m" ] 2>/dev/null; then
    printf '%s✓%s  command line tools are now %s\n%s│%s\n' "$G" "$X" "$(echo "$v" | cut -d. -f1-2)" "$D" "$X"
    RECEIPT+=("  ${G}✓${X} command line tools $CLT_OLD → $(echo "$v" | cut -d. -f1-2)"); CLT_OLD=""
  else
    printf '%s✗%s  still %s; brew will keep refusing to build until they'"'"'re updated\n%s│%s\n' "$R" "$X" "${v:-not installed}" "$D" "$X"
    RECEIPT+=("  ${R}✗${X} command line tools still out of date")
  fi
  return 0; }

# stop a running upgrade (quit, ctrl-c, closed window) instead of leaving brew running on its own
UP_JOB=""
upgrade_stop(){ local i
  [ -n "$UP_JOB" ] && kill -0 "$UP_JOB" 2>/dev/null || return 0
  pkill -TERM -P "$UP_JOB" 2>/dev/null || true; kill -TERM "$UP_JOB" 2>/dev/null || true
  for i in 1 2 3 4 5 6 7 8 9 10; do kill -0 "$UP_JOB" 2>/dev/null || break; sleep 1; done
  UP_JOB=""; RECEIPT+=("  ${Y}~${X} upgrade stopped partway; run ${B}dot upgrade${X} to see what's left")
  return 0; }

# what else comes along: brew's dry run of the ticked formulae -> UP_DEPS (upgraded) UP_NEW (installed)
upgrade_plan(){ local plan k n
  UP_DEPS=(); UP_NEW=()
  [ "$#" -gt 0 ] || return 0
  plan="$(HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade --dry-run --formula "$@" 2>/dev/null || true)"
  while IFS=$'\t' read -r k n; do case "$k" in up) UP_DEPS+=("$n") ;; new) UP_NEW+=("$n") ;; esac; done < <(printf '%s\n' "$plan" | awk '
    /^==> Would upgrade [0-9]+ dependenc/ { s = "up"; next }
    /^==> Would install [0-9]+ dependenc/ { s = "new"; next }
    /^==>/ { s = ""; next }
    s != "" && NF { n = $1; sub(/.*\//, "", n); print s "\t" n }')
  return 0; }

# the whole upgrade: tools warning, refresh offer, tick boxes, what comes along, then one row per package
upgrade_flow(){ local i j pid line LOG ok="" bad="" now other surprise="" ticked n
  local -a list f c; list=(); f=(); c=()
  # one brew at a time: two at once can wreck an app mid-upgrade
  other="$(pgrep -f 'brew\.rb (upgrade|install|reinstall|uninstall|bundle)' | head -1 || true)"
  if [ -n "$other" ]; then
    printf '%s✗%s  another brew is already running (pid %s, for %s). wait for it, or stop it: %skill %s%s\n' "$R" "$X" "$other" \
      "$(ps -o etime= -p "$other" | tr -d ' ')" "$B" "$other" "$X"
    RECEIPT+=("  ${R}✗${X} nothing upgraded: another brew was running (pid $other)"); return 0
  fi
  upgrade_scan
  if [ -n "$CLT_OLD" ]; then
    ui_menu "Xcode's command line tools are too old ($CLT_OLD on macOS $(sw_vers -productVersion | cut -d. -f1))"$'\n'"brew can't install anything that builds on this Mac (ghh is one) until they're updated" 0 \
      "Update them now|only the tools: no restart, asks for your Mac password" "Open Software Update|do it there yourself" "Skip for now|the rest can still upgrade"
    case "$UI_PICK" in
      0) clt_update ;;
      1) open "x-apple.systempreferences:com.apple.Software-Update-Settings.extension" 2>/dev/null || true
         RECEIPT+=("  ${Y}~${X} Software Update opened for the command line tools; run ${B}dot upgrade${X} again after") ;;
    esac
  fi
  ui_menu "brew's version info is $UP_AGE old" 0 "Use it|${#UP_N[@]} newer versions known" "Refresh first|brew update, takes about 10 seconds"
  if [ "$UI_PICK" = 1 ]; then
    printf '%s│%s  %srefreshing…%s' "$D" "$X" "$D" "$X"; brew update >/dev/null 2>&1 || true; printf '\r\033[K'
    UP_TMP=""; upgrade_scan
  fi
  if [ "${#UP_N[@]}" -eq 0 ]; then printf '%s✓%s  everything you installed is up to date\n' "$G" "$X"; RECEIPT+=("  ${G}✓${X} everything is up to date"); return 0; fi
  while :; do
    list=(); for i in "${!UP_N[@]}"; do list+=("${UP_N[$i]}|${UP_FROM[$i]} → ${UP_TO[$i]}${UP_NOTE[$i]:+   ${UP_NOTE[$i]}}|${UP_TICK[$i]}"); done
    ui_checklist "Upgrade which? (${#UP_N[@]} newer versions)" "${list[@]}"
    j=0; for i in $UI_TICKS; do UP_TICK[$j]=$i; j=$((j + 1)); done
    f=(); c=(); ticked=0
    for i in "${!UP_N[@]}"; do [ "${UP_TICK[$i]}" = 1 ] || continue; ticked=$((ticked + 1))
      if [ "${UP_KIND[$i]}" = cask ]; then c+=("${UP_FULL[$i]}"); else f+=("${UP_FULL[$i]}"); fi; done
    [ "$ticked" -gt 0 ] || { RECEIPT+=("  ${D}· nothing upgraded${X}"); return 0; }
    # what else comes along, and anything you unticked that a ticked package drags in anyway
    printf '%s│%s  %sworking out what else comes along…%s' "$D" "$X" "$D" "$X"
    upgrade_plan ${f[@]+"${f[@]}"}; printf '\r\033[K'
    surprise=""
    for n in ${UP_DEPS[@]+"${UP_DEPS[@]}"}; do for i in "${!UP_N[@]}"; do
      [ "${UP_N[$i]}" = "$n" ] && [ "${UP_TICK[$i]}" = 0 ] && surprise="$surprise, $n ${UP_FROM[$i]} → ${UP_TO[$i]}"; done; done
    n=$(( ticked + ${#UP_DEPS[@]} + ${#UP_NEW[@]} ))
    if [ -n "$surprise" ]; then line="⚠ also upgrades what you unticked, because a ticked package needs it: ${surprise#, }"
    else line="it downloads everything first, then installs; big ones (node, go, php) take a while"; fi
    ui_menu "That's $ticked ticked + ${#UP_DEPS[@]} dependency upgrade(s) + ${#UP_NEW[@]} new dependenc$([ "${#UP_NEW[@]}" = 1 ] && echo y || echo ies) ($n in all)"$'\n'"$line" 0 \
      "Go ahead|ctrl-c stops it cleanly" "Back to the list|change the ticks" "Cancel|"
    case "$UI_PICK" in 0) break ;; 1) continue ;; *) RECEIPT+=("  ${D}· nothing upgraded${X}"); return 0 ;; esac
  done
  for i in "${!UP_N[@]}"; do [ "${UP_TICK[$i]}" = 1 ] && row_add "${UP_N[$i]}" "${UP_FROM[$i]} → ${UP_TO[$i]}, queued"; done
  LOG="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/upgrade-$(date +%Y%m%d%H%M%S).log"; mkdir -p "$(dirname "$LOG")"; : > "$LOG"
  [ "$UI_TTY" = 1 ] || printf 'upgrading %s  (full output: %s)\n' "$n" "${LOG/#$HOME/~}"
  # one failing package doesn't stop the rest; each one is checked after
  { if [ "${#f[@]}" -gt 0 ]; then HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade --formula "${f[@]}" || true; fi
    if [ "${#c[@]}" -gt 0 ]; then HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade --cask "${c[@]}" || true; fi; } >> "$LOG" 2>&1 & pid=$!
  UP_JOB=$pid; trap 'upgrade_stop; ui_end; exit 130' INT TERM HUP; trap 'upgrade_stop; ui_end' EXIT
  ROW_HEAD="starting…"; rows_draw
  while kill -0 "$pid" 2>/dev/null; do
    # brew downloads everything first (✔︎ Bottle lines), then installs (🍺 lines)
    j=$(grep '^✔︎ Bottle ' "$LOG" 2>/dev/null | grep -vc '^✔︎ Bottle Manifest ' || true)
    i=$(grep -c '🍺' "$LOG" 2>/dev/null || true)
    line="$(grep -E '^==> (Upgrading|Installing) [^0-9]' "$LOG" | tail -1 | sed -E 's/^==> (Upgrading|Installing) //; s/ .*//; s|.*/||' || true)"
    if [ "${i:-0}" -gt 0 ] || [ -n "$line" ]; then ROW_HEAD="installing ${i:-0} of $n${line:+: $line}"
    else ROW_HEAD="downloading ${j:-0} of $n"; fi
    [ -n "$line" ] && row_set "$line" run "upgrading…"
    for i in "${!ROW_N[@]}"; do [ "${ROW_S[$i]}" = ok ] && continue
      grep -qE "🍺 +(/opt/homebrew/Cellar/${ROW_N[$i]}/|${ROW_N[$i]} was successfully)" "$LOG" 2>/dev/null && row_set "${ROW_N[$i]}" ok "done, checking"; done
    rows_draw; sleep 0.3
  done
  wait "$pid" 2>/dev/null || true; UP_JOB=""; ROW_HEAD=""
  # done means brew now has the new version, whatever the log said
  for i in "${!UP_N[@]}"; do [ "${UP_TICK[$i]}" = 1 ] || continue
    if [ "${UP_KIND[$i]}" = cask ]; then now="$(brew list --cask --versions "${UP_N[$i]}" 2>/dev/null | awk '{ print $NF }' || true)"
    else now="$(brew list --formula --versions "${UP_N[$i]}" 2>/dev/null | awk '{ print $NF }' || true)"; fi
    if [ "$now" = "${UP_TO[$i]}" ]; then row_set "${UP_N[$i]}" ok "${UP_FROM[$i]} → ${UP_TO[$i]}"; ok="$ok, ${UP_N[$i]}"
    else row_set "${UP_N[$i]}" fail "still ${now:-${UP_FROM[$i]}}, see the log"; bad="$bad, ${UP_N[$i]}"; fi
    row_print "${UP_N[$i]}"
  done
  rows_draw
  [ -n "$ok" ] && RECEIPT+=("  ${G}✓${X} upgraded    ${ok#, }")
  [ -n "$bad" ] && RECEIPT+=("  ${R}✗${X} not upgraded ${bad#, }  ${D}(log: ${LOG/#$HOME/~})${X}")
  [ "${#UP_DEPS[@]}" -gt 0 ] && RECEIPT+=("  ${D}· brew's plan also had ${#UP_DEPS[@]} dependency upgrade(s); the log has the details${X}")
  return 0; }

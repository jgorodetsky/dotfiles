#!/usr/bin/env bash
# clipfmt.sh - build, install and check clipfmt, for dott's clipfmt item. Each link rule (in
# rules.tsv and this Mac's ~/.config/clipfmt/local.tsv) is a part of the item.
#   clipfmt.sh --check           exit 0 when a rule is on and clipfmt runs; 1 when it needs a
#                                build or a start, or still runs with no rule on; 3 blocked; 5 when
#                                no rule is on. Then a line per rule: id TAB ok|off TAB what it does
#   clipfmt.sh --plan | apply    build when clipfmt.swift changed and start it at login; with no
#                                rule on, stop it and remove it
#   clipfmt.sh plan-on|on ID     turn a rule on (the first one builds and starts clipfmt)
#   clipfmt.sh plan-off|off ID   turn a rule off (the last one stops and removes clipfmt)
#   clipfmt.sh plan-remove|remove ID   remove your rule, or this Mac's format for a preset
#   clipfmt.sh list              the rules: id TAB where TAB example TAB pastes as
#   clipfmt.sh build             build, for the add and format flows, without starting it
#   clipfmt.sh uninstall         stop and remove clipfmt; the rules and what is on stay
#   clipfmt.sh test              build into a temp folder and run test.sh
#   clipfmt.sh rebuild           build again and restart, after an edit of clipfmt.swift
# it only reads for --check, --plan, plan-*, list. it never runs sudo. the program goes to
# ~/.local/bin/clipfmt, the agent to ~/Library/LaunchAgents.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
src="$here/clipfmt.swift"
rules="${CLIPFMT_RULES:-$here/rules.tsv}"
label="io.github.jgorodetsky.clipfmt"
bin="${CLIPFMT_BIN:-$HOME/.local/bin/clipfmt}"
state="$HOME/.local/state/clipfmt"
stamp="$state/built"
conf="${CLIPFMT_DIR:-$HOME/.config/clipfmt}"
local_rules="$conf/local.tsv"
enabled="$conf/enabled"
plist="$HOME/Library/LaunchAgents/$label.plist"
domain="gui/$(id -u)"
mine_marker="# your rules for every machine"

say() { printf '%s\n' "$*"; }
short() { local p="${1/#$here\//clipfmt/}"; say "${p/#$HOME/~}"; }
hash_src() { shasum -a 256 "$src" | cut -c1-16; }
built() { [ -x "$bin" ] && [ -f "$stamp" ] && [ "$(cat "$stamp")" = "$(hash_src)" ]; }
running() { launchctl print "$domain/$label" >/dev/null 2>&1; }
swiftc_ok() { xcrun --find swiftc >/dev/null 2>&1; }

# list: a line per rule id, this Mac's first: id TAB where TAB example TAB pastes as. where is
# "this Mac", "this Mac's format" (it hides the repo's), "preset" or "every machine".
list() {
  local l=/dev/null
  [ -f "$local_rules" ] && l="$local_rules"
  awk -v repo="$rules" '
    BEGIN { FS = "\t" }
    FILENAME == repo && index($0, "'"$mine_marker"'") == 1 { mine = 1 }
    /^#/ || NF != 5 { next }
    FILENAME == repo { if (!($1 in r)) { r[$1] = mine ? "every machine" : "preset"; rx[$1] = $4; rs[$1] = $5; ro[++n] = $1 } next }
    !($1 in l) { l[$1] = 1; lx[$1] = $4; ls[$1] = $5; lo[++m] = $1 }
    END {
      for (i = 1; i <= m; i++) { id = lo[i]; printf "%s\t%s\t%s\t%s\n", id, (id in r) ? "this Mac'\''s format" : "this Mac", lx[id], ls[id] }
      for (i = 1; i <= n; i++) { id = ro[i]; if (!(id in l)) printf "%s\t%s\t%s\t%s\n", id, r[id], rx[id], rs[id] }
    }' "$rules" "$l"
}
ids() { list | cut -f1; }
is_on() { grep -qx "$1" "$enabled" 2>/dev/null; }
# on_ids: the ids that are on and still have a rule
on_ids() { [ -f "$enabled" ] && grep -Fxf <(ids) "$enabled" || true; }
need_id() {
  [ -n "${1:-}" ] || { say "usage: clipfmt.sh $2 ID (one of: $(ids | tr '\n' ' '))" >&2; exit 2; }
  ids | grep -x "$1" >/dev/null || { say "no rule $1; the rules are: $(ids | tr '\n' ' ')" >&2; exit 2; }
}
where_of() { list | awk -F'\t' -v id="$1" '$1 == id { print $2 }'; }

# a link without https:// and with its middle cut: github.com/…/pull/1234
brief() {
  local u="${1#https://}" host rest
  host="${u%%/*}"
  rest="$(printf '%s' "${u#"$host"}" | awk -F/ '{ n = NF; if (n <= 3) print $0; else print "/…/" $(n-1) "/" $n }')"
  say "$host$rest"
}

parts() {
  list | while IFS=$'\t' read -r id where ex shows; do
    st=off
    is_on "$id" && st=ok
    printf '%s\t%s\t%s\n' "$id" "$st" "$(brief "$ex") → $shows · $where"
  done
}

# build DIR: compile with an Info.plist inside the binary and sign it with a fixed id, so macOS
# keeps one name for its "paste from other apps" setting.
build_in() {
  local out="$1"
  cat >"$out/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>$label</string>
  <key>CFBundleName</key><string>clipfmt</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
  swiftc -O -swift-version 5 -o "$out/clipfmt" "$src" \
    -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker "$out/Info.plist"
  codesign -f -s - -i "$label" "$out/clipfmt" 2>/dev/null
}

# build: test and build into ~/.local/bin when clipfmt.swift changed. It says whether it built.
build() {
  local tmp
  built && return 1
  # test.sh runs the flows, which build when needed, and a build runs test.sh
  [ -z "${CLIPFMT_IN_TEST:-}" ] || { say "clipfmt.sh: a build inside test.sh; the fake HOME has no build" >&2; exit 1; }
  swiftc_ok || { say "needs Xcode's command line tools: xcode-select --install" >&2; exit 1; }
  tmp="$(mktemp -d)"
  say "building clipfmt (swiftc, about 10 seconds)"
  build_in "$tmp"
  bash "$here/test.sh" "$tmp/clipfmt" >/dev/null || { bash "$here/test.sh" "$tmp/clipfmt" || true; rm -r "$tmp"; say "test.sh failed: nothing installed" >&2; exit 1; }
  mkdir -p "$(dirname "$bin")" "$state"
  mv "$tmp/clipfmt" "$bin"
  rm -r "$tmp"
  hash_src >"$stamp"
}

write_plist() {
  mkdir -p "$(dirname "$plist")" "$state"
  cat >"$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array><string>$bin</string><string>--rules</string><string>$rules</string><string>run</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardErrorPath</key><string>$state/clipfmt.log</string>
</dict></plist>
PLIST
}

install() {
  local rebuilt=0 before=""
  build && rebuilt=1
  [ -L "$conf/rules.tsv" ] && rm -f "$conf/rules.tsv" # an older clipfmt linked the repo's rules here
  [ -f "$plist" ] && before="$(cat "$plist")"
  write_plist
  if running && [ "$before" != "$(cat "$plist")" ]; then
    launchctl bootout "$domain/$label" 2>/dev/null || true # a new plist needs a new load
  fi
  if ! running; then
    launchctl bootstrap "$domain" "$plist"
  elif [ "$rebuilt" = 1 ]; then
    launchctl kickstart -k "$domain/$label"
  fi
}

uninstall() {
  if running; then launchctl bootout "$domain/$label" 2>/dev/null || true; fi
  rm -f "$plist" "$bin" "$stamp"
}

install_plan() {
  built || say "build $(short "$bin") from clipfmt/clipfmt.swift, after test.sh passes"
  running || say "start it at login: $(short "$plist")"
}

set_on() {
  mkdir -p "$conf"
  { [ -f "$enabled" ] && grep -vx "$1" "$enabled"; [ "$2" = on ] && say "$1"; } | sort -u >"$enabled.tmp" || true
  mv "$enabled.tmp" "$enabled"
}

case "${1:-}" in
  --check)
    if [ -z "$(on_ids)" ]; then
      if [ -f "$plist" ] || running; then say "clipfmt still runs with no rule on"; say "stop it and remove it"; code=1
      else say "off: no link rule is on"; say "turn a rule on below"; code=5; fi
    elif ! swiftc_ok; then say "needs Xcode's command line tools to build"; say "xcode-select --install"; code=3
    elif [ ! -x "$bin" ]; then say "not built yet"; say "build it and start it at login"; code=1
    elif ! built; then say "clipfmt.swift changed since the build"; say "build it again"; code=1
    elif ! running; then say "built, but the login agent isn't running"; say "start it"; code=1
    else say "on: $(on_ids | tr '\n' ' ')- copied links paste short; clipfmt runs at login"; say ""; code=0; fi
    parts
    exit "$code"
    ;;
  --plan)
    if [ -z "$(on_ids)" ]; then say "no rule is on: stop clipfmt and remove $(short "$bin") and $(short "$plist")"
    else install_plan; fi
    ;;
  apply)
    if [ -z "$(on_ids)" ]; then uninstall; say "no rule is on: clipfmt stopped and removed"
    else install; fi
    ;;
  plan-on)
    need_id "${2:-}" on
    say "turn $2 on: $(list | awk -F'\t' -v id="$2" '$1 == id { print $3 " pastes as " $4 }')"
    install_plan
    ;;
  on)
    need_id "${2:-}" on
    install
    set_on "$2" on
    say "$2 on"
    ;;
  plan-off)
    need_id "${2:-}" off
    say "turn $2 off"
    [ "$(on_ids | grep -vx "$2" || true)" = "" ] && say "no rule left on: stop clipfmt and remove $(short "$bin") and $(short "$plist")"
    true
    ;;
  off)
    need_id "${2:-}" off
    set_on "$2" off
    say "$2 off"
    if [ -z "$(on_ids)" ]; then uninstall; say "no rule left on: clipfmt stopped and removed"; fi
    ;;
  plan-remove | remove)
    need_id "${2:-}" remove
    w="$(where_of "$2")"
    case "$w" in
      preset) say "$2 is a preset, so it stays: turn it off, or change its format" >&2; exit 1 ;;
      "this Mac") file="$local_rules"; what="remove $2 from $(short "$local_rules") and turn it off" ;;
      "this Mac's format") file="$local_rules"; what="remove this Mac's format for $2: the repo's comes back" ;;
      *) file="$rules"; what="remove $2 from $(short "$rules"), on every machine, and turn it off here" ;;
    esac
    if [ "$1" = plan-remove ]; then say "$what"; exit 0; fi
    [ -L "$file" ] && { say "$(short "$file") is a link; change it by hand" >&2; exit 1; }
    awk -F'\t' -v id="$2" '/^#/ || $1 != id' "$file" >"$file.tmp" && mv "$file.tmp" "$file"
    if [ "$w" != "this Mac's format" ]; then
      set_on "$2" off
      [ -z "$(on_ids)" ] && uninstall
    fi
    say "$2 removed"
    ;;
  list) list ;;
  build) build || true ;;
  uninstall) uninstall; say "clipfmt stopped and removed; the rules and what is on stay" ;;
  test)
    tmp="$(mktemp -d)"
    trap 'rm -r "$tmp"' EXIT
    swiftc_ok || { say "needs Xcode's command line tools: xcode-select --install" >&2; exit 1; }
    build_in "$tmp"
    bash "$here/test.sh" "$tmp/clipfmt"
    ;;
  rebuild)
    rm -f "$stamp"
    install
    say "rebuilt and restarted"
    ;;
  *)
    sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
    ;;
esac

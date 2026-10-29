#!/usr/bin/env bash
# clipfmt.sh - build, install and check clipfmt, for dott's clipfmt-<type> items (one per link type).
#   clipfmt.sh --check TYPE   exit 0 when TYPE is on and clipfmt runs, 1 when not yet, 3 when blocked (only reads)
#   clipfmt.sh --plan TYPE    what enable TYPE would do (only reads)
#   clipfmt.sh enable TYPE    test, build when clipfmt.swift changed, start the login agent, turn TYPE on
#   clipfmt.sh disable TYPE   turn TYPE off; with no type left on, stop and remove clipfmt
#   clipfmt.sh test           build into a temp folder and check every row of cases.tsv
#   clipfmt.sh rebuild        build again and restart, after an edit of clipfmt.swift
# it never runs sudo. the program goes to ~/.local/bin/clipfmt, the agent to ~/Library/LaunchAgents.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$here/clipfmt.swift"
label="io.github.jgorodetsky.clipfmt"
bin="$HOME/.local/bin/clipfmt"
state="$HOME/.local/state/clipfmt"
stamp="$state/built"
conf="${CLIPFMT_DIR:-$HOME/.config/clipfmt}"
plist="$HOME/Library/LaunchAgents/$label.plist"
domain="gui/$(id -u)"
types="$(awk -F'\t' '!/^#/ && NF == 3 { print $1 }' "$here/rules.tsv" | sort -u)"

say() { printf '%s\n' "$*"; }
hash_src() { shasum -a 256 "$src" "$here/clipfmt.sh" | shasum -a 256 | cut -c1-16; }
built() { [ -x "$bin" ] && [ -f "$stamp" ] && [ "$(cat "$stamp")" = "$(hash_src)" ]; }
running() { launchctl print "$domain/$label" >/dev/null 2>&1; }
is_on() { grep -qx "$1" "$conf/enabled" 2>/dev/null; }
need_type() {
  [ -n "${1:-}" ] || { say "usage: clipfmt.sh ${2:-enable} TYPE (one of: $(echo $types))" >&2; exit 2; }
  grep -qx "$1" <<<"$types" || { say "no type $1 in rules.tsv; the types are: $(echo $types)" >&2; exit 2; }
}
swiftc_ok() { xcrun --find swiftc >/dev/null 2>&1; }

# build DIR: compile with an Info.plist inside the binary and sign it with a fixed id, so macOS
# keeps one name for its "paste from other apps" setting.
build() {
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

# cases BIN: check every row of cases.tsv with the rules in this folder.
cases() {
  local b="$1" tmp fail=0 url want got
  tmp="$(mktemp -d)"
  cp "$here/rules.tsv" "$tmp/rules.tsv"
  while IFS=$'\t' read -r url want; do
    case "$url" in '#'* | '') continue ;; esac
    [ "$want" = - ] && want=unchanged
    got="$(CLIPFMT_DIR="$tmp" "$b" test "$url")"
    case "$got" in
      "$want" | "$want:"*) ;;
      *) say "FAIL $url: got \"$got\", want \"$want\""; fail=1 ;;
    esac
  done <"$here/cases.tsv"
  rm -r "$tmp"
  return "$fail"
}

write_plist() {
  mkdir -p "$(dirname "$plist")" "$state"
  cat >"$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array><string>$bin</string><string>run</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardErrorPath</key><string>$state/clipfmt.log</string>
</dict></plist>
PLIST
}

# install: test and build when the source changed, link the rules, (re)start the agent.
install() {
  local rebuilt=0 tmp
  if ! built; then
    tmp="$(mktemp -d)"
    say "building clipfmt (swiftc, about 10 seconds)"
    build "$tmp"
    cases "$tmp/clipfmt" || { rm -r "$tmp"; say "cases.tsv failed: nothing installed" >&2; exit 1; }
    mkdir -p "$(dirname "$bin")" "$state"
    mv "$tmp/clipfmt" "$bin"
    rm -r "$tmp"
    hash_src >"$stamp"
    rebuilt=1
  fi
  mkdir -p "$conf"
  ln -sfn "$here/rules.tsv" "$conf/rules.tsv"
  write_plist
  if ! running; then
    launchctl bootstrap "$domain" "$plist"
  elif [ "$rebuilt" = 1 ]; then
    launchctl kickstart -k "$domain/$label"
  fi
}

case "${1:-}" in
  --check)
    need_type "${2:-}" --check
    if [ "$(uname)" != Darwin ]; then say "clipfmt is for macOS"; exit 4; fi
    if ! swiftc_ok; then say "needs Xcode's command line tools to build"; say "xcode-select --install"; exit 3; fi
    if [ ! -x "$bin" ]; then say "not built yet"; say "build it and start it at login"; exit 1; fi
    if ! built; then say "clipfmt.swift changed since the build"; say "build it again"; exit 1; fi
    if ! running; then say "built, but the login agent isn't running"; say "start it"; exit 1; fi
    if ! is_on "$2"; then say "$2 links are off"; say "turn them on"; exit 1; fi
    say "on: copied $2 links paste as short links (clipfmt runs at login)"
    ;;
  --plan)
    need_type "${2:-}" --plan
    built || say "build ${bin/#$HOME/~} from clipfmt/clipfmt.swift and check every row of cases.tsv first"
    running || say "start it at login: ${plist/#$HOME/~}"
    is_on "$2" || say "turn $2 links on in ${conf/#$HOME/~}/enabled"
    ;;
  enable)
    need_type "${2:-}" enable
    swiftc_ok || { say "needs Xcode's command line tools: xcode-select --install" >&2; exit 1; }
    install
    "$bin" on "$2"
    ;;
  disable)
    need_type "${2:-}" disable
    if [ -f "$conf/enabled" ]; then
      grep -vx "$2" "$conf/enabled" >"$conf/enabled.tmp" || true
      mv "$conf/enabled.tmp" "$conf/enabled"
    fi
    say "$2 links off"
    if [ ! -s "$conf/enabled" ]; then
      running && launchctl bootout "$domain/$label"
      rm -f "$plist" "$bin" "$stamp" "$conf/rules.tsv" "$conf/enabled"
      say "no type left on: clipfmt stopped and removed"
    fi
    ;;
  test)
    tmp="$(mktemp -d)"
    trap 'rm -r "$tmp"' EXIT
    build "$tmp"
    cases "$tmp/clipfmt"
    say "every case passed"
    ;;
  rebuild)
    rm -f "$stamp"
    install
    say "rebuilt and restarted"
    ;;
  *)
    sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
    ;;
esac

#!/usr/bin/env bash
# test.sh BIN - every check of a clipfmt build: each rule's example (selftest), cases.tsv, the
# helpers that make rules (parts, make, groups, render), and flows.sh and clipfmt.sh on a fake
# HOME, where stubs stand in for dott --pick, launchctl and xcrun. It never reads the clipboard
# and never touches the real HOME or the repo's rules.tsv. clipfmt.sh test builds BIN and runs it.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
b="$(cd "$(dirname "$1")" && pwd -P)/$(basename "$1")"
t="$(mktemp -d)"
trap 'rm -r "$t"' EXIT
fail=0
say() { printf '%s\n' "$*"; }
bad() { say "FAIL $*"; fail=1; }
mkdir -p "$t/empty"
export CLIPFMT_DIR="$t/empty" CLIPFMT_RULES="$here/rules.tsv" CLIPFMT_IN_TEST=1

# 1. each rule's example pastes as its last column, and no earlier rule takes it
"$b" selftest >/dev/null || { "$b" selftest || true; fail=1; }

# 2. cases.tsv
while IFS=$'\t' read -r url want; do
  case "$url" in '#'* | '') continue ;; esac
  [ "$want" = - ] && want=unchanged
  got="$("$b" test "$url")"
  got="${got% (off)}"
  case "$got" in "$want" | "$want:"*) ;; *) bad "$url: got \"$got\", want \"$want\"" ;; esac
done <"$here/cases.tsv"

# 3. the helpers the add and format flows use
want() { local w="$1" got; shift; got="$("$b" "$@" 2>&1)" || got="exit $?: $got"; [ "$got" = "$w" ] || bad "clipfmt $*: got \"$got\", want \"$w\""; }
fails() { local w="$1" got; shift; if got="$("$b" "$@" 2>&1)"; then bad "clipfmt $* worked: $got"; elif [[ "$got" != *"$w"* ]]; then bad "clipfmt $*: \"$got\" doesn't say \"$w\""; fi; }
lin=https://linear.app/acme/issue/ENG-123/fix-login
re='^https://(?i:linear\.app)/([^/?#]+)/(issue)/([^/?#]+)/([^/?#]+)(?:[/?#].*)?$'
want "host linear.app
1 acme
2 issue
3 ENG-123
4 fix-login" parts "$lin"
want "$re" make "$lin" --vary 1,3,4
want '{1} acme
{2} issue
{3} ENG-123
{4} fix-login' groups "$re" "$lin"
want 'ENG-9: add dark mode' render "$re" '{3}: {4:words}' https://linear.app/other/issue/ENG-9/add-dark-mode
want '$5 \1 ENG-9 on linear.app' render "$re" '$5 \1 {3} on {host}' https://LINEAR.app/other/issue/ENG-9/x
want '{3' render "$re" '{3' "$lin"
want '^https://(?i:github\.com)/(o)/(r)/(pull)/([0-9]+)(?:[/?#].*)?$' make https://github.com/o/r/pull/12 --vary 4
want '^https://[^/?#]+/(browse)/([^/?#]+)(?:[/?#].*)?$' make https://jira.example.dev/browse/ACME-1 --vary 2 --any-host
fails 'no {9}: {1} to {4} are there' render "$re" '{9}' "$lin"
fails '{x}: use {1}' render "$re" '{x}' "$lin"
fails 'pastes as nothing' render "$re" '' "$lin"
fails "doesn't match" render "$re" '{3}' https://github.com/o/r/pull/1
fails 'https link' make http://linear.app/a/issue/B-1/c --vary 1
fails 'no part 5' make "$lin" --vary 5
fails 'keep a part fixed' make https://x.example/a/b --vary 1,2 --any-host
fails 'at least one part' make "$lin" --vary ''
fails 'https link' parts 'not a link'

# 4. the flows and clipfmt.sh on a fake HOME
home="$t/home" s="$t/stubs"
mkdir -p "$s"
# a build in the fake HOME, so the flows don't build one
put_build() {
  mkdir -p "$home/.local/bin" "$home/.local/state/clipfmt"
  cp "$b" "$home/.local/bin/clipfmt"
  shasum -a 256 "$here/clipfmt.swift" | cut -c1-16 >"$home/.local/state/clipfmt/built"
}
put_build
cp "$here/rules.tsv" "$t/rules.tsv"
cat >"$s/dott" <<'STUB'
#!/usr/bin/env bash
# dott --pick, answered from $PICKS (one line per call, | between several picks). A list answer
# must be one of the lines offered; a text answer runs the preview with it as {q}.
set -euo pipefail
[ "${1:-}" = --pick ] || { echo "stub: not --pick: $*" >&2; exit 2; }
shift
input=0 preview="" prompt=""
while [ $# -gt 0 ]; do
  case "$1" in
    --input) input=1 ;;
    --prompt) prompt="$2"; shift ;;
    --query | --header) shift ;;
    --preview) preview="$2"; shift ;;
  esac
  shift
done
ans="$(head -n1 "$PICKS")"
tail -n +2 "$PICKS" >"$PICKS.t" && mv "$PICKS.t" "$PICKS"
echo "pick $prompt: $ans" >>"$PICKLOG"
[ "$ans" = "<esc>" ] && exit 1
if [ "$input" = 1 ]; then
  q="'$ans'"
  if [ -n "$preview" ]; then sh -c "${preview//\{q\}/$q}" >>"$PICKLOG" 2>&1 || true; fi
  printf '%s\n' "$ans"
  exit 0
fi
lines="$(cat)"
printf '%s\n' "$ans" | tr '|' '\n' | while IFS= read -r a; do
  printf '%s\n' "$lines" | grep -Fx -- "$a" >/dev/null || { echo "stub: \"$a\" isn't offered at $prompt" >&2; exit 3; }
  printf '%s\n' "$a"
done
STUB
cat >"$s/launchctl" <<'STUB'
#!/bin/sh
echo "launchctl $*" >>"$PICKLOG"
case "$1" in
  print) [ -f "$STUBS/loaded" ] ;;
  bootstrap) touch "$STUBS/loaded" ;;
  bootout) rm -f "$STUBS/loaded" ;;
esac
STUB
printf '#!/bin/sh\necho /usr/bin/swiftc\n' >"$s/xcrun"
chmod +x "$s/dott" "$s/launchctl" "$s/xcrun"

# flow PICKS STDIN ARGS...: run flows.sh (or clipfmt.sh, when ARGS start with clipfmt.sh) there
flow() {
  local picks="$1" in="$2" sh=flows.sh
  shift 2
  [ "$1" = clipfmt.sh ] && { sh=clipfmt.sh; shift; }
  printf '%s\n' "$picks" >"$t/picks"
  printf '%b' "$in" | HOME="$home" PATH="$s:$PATH" DOTT="$s/dott" PICKS="$t/picks" PICKLOG="$t/log" STUBS="$s" \
    CLIPFMT_RULES="$t/rules.tsv" CLIPFMT_DIR="$home/.config/clipfmt" CLIPFMT_BIN="$home/.local/bin/clipfmt" CLIPFMT_NO_CLIPBOARD=1 \
    bash "$here/$sh" "$@"
}
expect() { # expect WHAT GOT WANT
  [ "$2" = "$3" ] || bad "$1: got \"$2\", want \"$3\""
}
local_tsv="$home/.config/clipfmt/local.tsv"

# add, this Mac only: a bad format and a taken name are asked again
: >"$t/log"
out="$(flow "$lin
1 acme|3 ENG-123|4 fix-login
only linear.app
{9}
{3}: {4:words}
linear
lin
this Mac only (~/.config/clipfmt/local.tsv)" 'n\n' add 2>&1)" || bad "add: exit $?: $out"
expect "add: local.tsv" "$(cat "$local_tsv" 2>/dev/null)" "$(printf 'lin\t%s\t{3}: {4:words}\t%s\tENG-123: fix login' "$re" "$lin")"
[[ "$out" == *"no {9}"* && "$out" == *"linear is taken"* ]] || bad "add didn't say why it asked again: $out"
grep -qx "ENG-123: fix login" "$t/log" || bad "the format's preview didn't show ENG-123: fix login: $(cat "$t/log")"
grep -qx "host linear.app · 1 acme · 2 issue · 3 ENG-123 · 4 fix-login" "$t/log" || bad "the example link's preview didn't show its parts"
expect "add: the rules file" "$(cmp -s "$t/rules.tsv" "$here/rules.tsv" && echo same)" same
out="$(flow "" "" clipfmt.sh --check)" && code=0 || code=$?
expect "--check with nothing on" "$code" 5
[[ "$out" == *$'\nlin\toff\tlinear.app/…/ENG-123/fix-login → ENG-123: fix login · this Mac'* ]] || bad "--check doesn't list lin: $out"

# on, then off: the first rule on starts the agent with the repo's rules, the last one off removes it
out="$(flow "" "" clipfmt.sh on lin 2>&1)" || bad "on lin: $out"
grep -q "launchctl bootstrap" "$t/log" || bad "on didn't start the agent: $(cat "$t/log")"
grep -q "<string>--rules</string><string>$t/rules.tsv</string>" "$home/Library/LaunchAgents/io.github.jgorodetsky.clipfmt.plist" || bad "the plist doesn't pass the rules file"
out="$(flow "" "" clipfmt.sh --check)" && code=0 || code=$?
expect "--check with lin on" "$code" 0
[[ "$out" == *$'\nlin\tok\t'* ]] || bad "--check doesn't show lin on: $out"
expect "test a lin link" "$(CLIPFMT_DIR="$home/.config/clipfmt" CLIPFMT_RULES="$t/rules.tsv" "$b" test https://linear.app/x/issue/ENG-9/y)" "lin: ENG-9: y"
out="$(flow "" "" clipfmt.sh off lin 2>&1)" || bad "off lin: $out"
[ ! -e "$home/Library/LaunchAgents/io.github.jgorodetsky.clipfmt.plist" ] && [ ! -e "$home/.local/bin/clipfmt" ] || bad "off with nothing left on didn't remove clipfmt"
[ -f "$local_tsv" ] || bad "removing clipfmt took local.tsv"
put_build

# format a preset: this Mac's copy hides it, and remove brings the preset back
out="$(flow 'PR {3} in {2}' '' format pr 2>&1)" || bad "format pr: $out"
expect "pr after format" "$(CLIPFMT_DIR="$home/.config/clipfmt" CLIPFMT_RULES="$t/rules.tsv" "$b" test https://github.com/o/dott/pull/7)" "pr: PR 7 in dott (off)"
expect "pr's place" "$(flow "" "" clipfmt.sh list | awk -F'\t' '$1 == "pr" { print $2 }')" "this Mac's format"
out="$(flow "" "" clipfmt.sh remove pr 2>&1)" || bad "remove pr's format: $out"
expect "pr after remove" "$(flow "" "" clipfmt.sh list | awk -F'\t' '$1 == "pr" { print $2 }')" preset
out="$(flow "" "" clipfmt.sh remove pr 2>&1)" && bad "remove a preset worked: $out"

# format a rule with two lines: the format must fit both
out="$(flow '{2}
{1}!' '' format jira 2>&1)" || bad "format jira: $out"
expect "jira's lines" "$(awk -F'\t' '$1 == "jira" { print $5 }' "$local_tsv" | paste -sd, -)" "DEV-1900!,DEV-1901!"

# add, every machine, on a host that isn't public: it shows the line and wants a typed yes
out="$(flow 'https://jira.example.dev/browse/ACME-1
2 ACME-1
any host (a tool that runs on many domains, like Jira)
{2}
acme
every machine (the repo'"'"'s clipfmt/rules.tsv, which is public)' 'yes\nn\n' add 2>&1)" || bad "add for every machine: $out"
[[ "$out" == *"not a public site"* ]] || bad "add for every machine didn't warn about the host: $out"
expect "the rules file's last line" "$(tail -n1 "$t/rules.tsv" | cut -f1,3,5)" "$(printf 'acme\t{2}\tACME-1')"
out="$(flow "https://jira.example.dev/browse/ACME-2
2 ACME-2
only jira.example.dev
{2}
acme2
every machine (the repo's clipfmt/rules.tsv, which is public)" 'no\n' add 2>&1)" && bad "add without a typed yes worked"
expect "after no yes" "$(grep -c '^acme2' "$t/rules.tsv" || true)" 0
out="$(flow "" "" clipfmt.sh remove acme 2>&1)" || bad "remove acme: $out"
expect "after remove acme" "$(grep -c '^acme' "$t/rules.tsv" || true)" 0
put_build # with no rule on, remove took clipfmt away too

# esc stops with 130 and writes nothing
before="$(cat "$local_tsv")"
out="$(flow '<esc>' '' add 2>&1)" && code=0 || code=$?
expect "esc in add" "$code" 130
expect "local.tsv after esc" "$(cat "$local_tsv")" "$before"

# local.tsv must be this Mac's own file, never a link
mv "$local_tsv" "$t/elsewhere.tsv" && ln -s "$t/elsewhere.tsv" "$local_tsv"
out="$(flow 'x' '' format lin 2>&1)" && bad "format wrote through a link: $out"
rm "$local_tsv" && mv "$t/elsewhere.tsv" "$local_tsv"

[ "$fail" = 0 ] && say "every check passed"
exit "$fail"

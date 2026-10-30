#!/usr/bin/env bash
# flows.sh - the questions behind dott clipfmt's add, format and test rows. They ask with dott's
# own picker ("$DOTT" --pick), so they run from dott, or with DOTT pointing at a dott.
#   flows.sh add          a new link rule from one example link: its parts, its host, its format
#                         (with a live preview), its name, and this Mac only or every machine
#   flows.sh format ID    a new format for a rule; for a repo rule, this Mac's own copy
#   flows.sh test         what a copied link pastes as, as you type it
# exit 130 means you stopped (esc or ctrl-c). Nothing is written before the last question.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
export CLIPFMT_RULES="${CLIPFMT_RULES:-$here/rules.tsv}"
export CLIPFMT_DIR="${CLIPFMT_DIR:-$HOME/.config/clipfmt}"
export CLIPFMT_BIN="${CLIPFMT_BIN:-$HOME/.local/bin/clipfmt}"
export CLIPFMT_FLOWS="$here/flows.sh"
local_rules="$CLIPFMT_DIR/local.tsv"
public_hosts="github.com gitlab.com linear.app"

say() { printf '%s\n' "$*"; }
stop() { exit 130; }
cf() { "$CLIPFMT_BIN" --rules "$CLIPFMT_RULES" "$@"; }
pick() { "${DOTT:-dott}" --pick "$@"; }
yes_no() { # yes_no QUESTION DEFAULT(y|n)
  local a
  printf '%s ' "$1"
  read -r a || a=""
  case "${a:-$2}" in y | Y | yes) return 0 ;; *) return 1 ;; esac
}
ids() { bash "$here/clipfmt.sh" list | cut -f1; }

# the helper commands (parts, make, render) are clipfmt's own, so a preview shows what clipfmt does
need_helper() { bash "$here/clipfmt.sh" build; }
# clip: the copied link, to start the example with; tests set CLIPFMT_NO_CLIPBOARD
clip() { [ -n "${CLIPFMT_NO_CLIPBOARD:-}" ] || cf clip-url 2>/dev/null || true; }

# groups_header PATTERN URL: {1} acme · {2} issue ..., then what else a format takes
groups_header() {
  cf groups "$1" "$2" | awk '{ k = $1; $1 = ""; sub(/^ /, ""); printf "%s%s %s", (NR > 1 ? " · " : ""), k, $0 } END { print "" }'
  say "{N:words} turns - _ or + into spaces · {host} is the link's host · esc stops"
}

# write_local ID LINES: this Mac's lines for ID, in place of any it had. local.tsv stays a file
# of its own: a link could put this Mac's rules in a repo.
write_local() {
  [ -L "$local_rules" ] && { say "$local_rules is a link; it must be this Mac's own file" >&2; exit 1; }
  mkdir -p "$CLIPFMT_DIR"
  touch "$local_rules"
  { awk -F'\t' -v id="$1" '$1 != id' "$local_rules"; printf '%s\n' "$2"; } >"$local_rules.tmp"
  mv "$local_rules.tmp" "$local_rules"
}

add() {
  need_helper
  local url vary host any="" re fmt shows name sug where line h
  url="$(pick --input --prompt "example link" --query "$(clip)" \
    --header "a link of the kind to paste short (from the clipboard when it holds one); its parts show below" \
    --preview 'bash "$CLIPFMT_FLOWS" parts-line {q}')" || stop
  cf parts "$url" >/dev/null || exit 1
  host="$(cf parts "$url" | sed -n 's/^host //p')"
  vary="$(cf parts "$url" | grep -v '^host ' |
    pick --multi --prompt "which parts change from link to link?" --header "tab picks each one, enter when done")" || stop
  vary="$(printf '%s\n' "$vary" | cut -d' ' -f1 | paste -sd, -)"
  h="$(printf '%s\n' "only $host" "any host (a tool that runs on many domains, like Jira)" | pick --prompt "which host?")" || stop
  case "$h" in any*) any=--any-host ;; esac
  re="$(cf make "$url" --vary "$vary" $any)" || exit 1
  export CLIPFMT_RE="$re" CLIPFMT_URL="$url"
  fmt="$(printf '{%s} ' ${vary//,/ } | sed 's/ $//')"
  while :; do
    fmt="$(pick --input --prompt "format" --query "$fmt" \
      --header "$(groups_header "$re" "$url")" \
      --preview '"$CLIPFMT_BIN" render "$CLIPFMT_RE" {q} "$CLIPFMT_URL" 2>&1')" || stop
    shows="$(cf render "$re" "$fmt" "$url" 2>&1)" && break
    say "$shows"
  done
  sug="$(printf '%s' "${host#www.}" | cut -d. -f1 | tr 'A-Z' 'a-z')"
  while :; do
    name="$(pick --input --prompt "its name" --query "$sug" --header "a-z, 0-9 and -; it is the rule's row in dott clipfmt")" || stop
    if ! printf '%s' "$name" | grep -Eq '^[a-z0-9][a-z0-9-]*$'; then say "$name: use a-z, 0-9 and -"
    elif ids | grep -x "$name" >/dev/null; then say "$name is taken; pick another name"
    else break; fi
  done
  where="$(printf '%s\n' "this Mac only (~/.config/clipfmt/local.tsv)" "every machine (the repo's clipfmt/rules.tsv, which is public)" |
    pick --prompt "where does it go?")" || stop
  line="$(printf '%s\t%s\t%s\t%s\t%s' "$name" "$re" "$fmt" "$url" "$shows")"
  case "$where" in
    every*)
      [ -L "$CLIPFMT_RULES" ] && { say "$CLIPFMT_RULES is a link; add the line by hand" >&2; exit 1; }
      say "this line goes in the repo's clipfmt/rules.tsv, which is public:"
      say "  $line"
      if [[ " $public_hosts " == *" $host "* ]]; then
        yes_no "put it there? [y/N]" n || stop
      else
        say "$host is not a public site: check that the line names no employer, client or person."
        printf 'type yes to put it there: '
        read -r h || h=""
        [ "$h" = yes ] || stop
      fi
      printf '%s\n' "$line" >>"$CLIPFMT_RULES"
      ;;
    *) write_local "$name" "$line" ;;
  esac
  say "$name: links like $url paste as $shows"
  if yes_no "turn it on now? [Y/n]" y; then bash "$here/clipfmt.sh" on "$name"; fi
}

format() {
  local id="${1:-}" lines first re fmt url shows out="" ok
  ids | grep -x "$id" >/dev/null || { say "no rule ${id:-?}; the rules are: $(ids | tr '\n' ' ')" >&2; exit 2; }
  need_helper
  # the rule's lines, this Mac's when it has its own
  lines="$( { [ -f "$local_rules" ] && awk -F'\t' -v id="$id" '$1 == id && !/^#/' "$local_rules"; } || true)"
  [ -n "$lines" ] || lines="$(awk -F'\t' -v id="$id" '$1 == id && !/^#/' "$CLIPFMT_RULES")"
  first="$(printf '%s\n' "$lines" | head -n1)"
  re="$(printf '%s' "$first" | cut -f2)"
  fmt="$(printf '%s' "$first" | cut -f3)"
  url="$(printf '%s' "$first" | cut -f4)"
  export CLIPFMT_RE="$re" CLIPFMT_URL="$url"
  while :; do
    fmt="$(pick --input --prompt "$id format" --query "$fmt" --header "$(groups_header "$re" "$url")" \
      --preview '"$CLIPFMT_BIN" render "$CLIPFMT_RE" {q} "$CLIPFMT_URL" 2>&1')" || stop
    out="" ok=1
    while IFS=$'\t' read -r i r f u s; do
      if ! shows="$(cf render "$r" "$fmt" "$u" 2>&1)"; then say "for $u: $shows"; ok=0; break; fi
      out+="$(printf '%s\t%s\t%s\t%s\t%s' "$i" "$r" "$fmt" "$u" "$shows")"$'\n'
    done <<<"$lines"
    [ "$ok" = 1 ] && break
  done
  write_local "$id" "${out%$'\n'}"
  say "$id: $url pastes as $(printf '%s' "$out" | head -n1 | cut -f5) on this Mac"
  bash "$here/clipfmt.sh" list | awk -F'\t' -v id="$id" '$1 == id && $2 == "this Mac'\''s format" { print "the repo'\''s format stays for other machines; remove " id " here to go back to it" }'
}

test_link() {
  need_helper
  pick --input --prompt "a link" --query "$(clip)" \
    --header "what a copied link pastes as, with the rules on and off; esc or enter when done" \
    --preview '"$CLIPFMT_BIN" --rules "$CLIPFMT_RULES" test {q} 2>&1' >/dev/null || true
}

case "${1:-}" in
  add) add ;;
  format) format "${2:-}" ;;
  test) test_link ;;
  parts-line) cf parts "${2:-}" 2>&1 | awk '{ printf "%s%s", (NR > 1 ? " · " : ""), $0 } END { print "" }' ;; # the add flow's preview
  *)
    sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
    ;;
esac

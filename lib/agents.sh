# agents.sh - agent tools: the skills and the one global rules file. sourced by install.sh and
# dot, not run. works in bash 3.2 (macOS).
#
# skills come from the repo's agents/skills (public) and ~/engine/skills (private, when it's
# there). npx skills puts one real copy in ~/.agents/skills, which codex, opencode, copilot, pi,
# cursor and gemini read, and links ~/.claude/skills/NAME to it for claude. it overwrites without
# asking, so a hash of every copy installed is kept to tell your edits from repo updates.

SK_NPX="skills@1.7.4"; SK_REF="skills-ref==0.1.1"
SK_HOME="$HOME/.agents/skills"; SK_CLAUDE="$HOME/.claude/skills"
SK_PRIV="${DOT_PRIVATE_SKILLS:-$HOME/engine/skills}"
SK_REC="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/skills.sync"
# these read ~/.agents/skills, so naming them never adds a folder of their own
SK_AGENTS="codex opencode github-copilot pi cursor gemini-cli"
if command -v shasum >/dev/null 2>&1; then SK_SUM="shasum -a 256"; else SK_SUM=sha256sum; fi

sk_claude(){ [ -d "$HOME/.claude" ] || command -v claude >/dev/null 2>&1; }
sk_files(){ ( cd "$1" && find . -type f ! -name .dotfiles ! -name .DS_Store ! -path '*/__pycache__/*' | sed 's|^\./||' | LC_ALL=C sort ); }
# one hash for a skill folder: every file's name and contents
sk_hash(){ [ -d "$1" ] || { echo -; return 0; }
  ( cd "$1" && sk_files . | while IFS= read -r f; do printf '%s  %s\n' "$($SK_SUM < "$f" | cut -c1-64)" "$f"; done ) | $SK_SUM | cut -c1-16; }
sk_rec(){ awk -F'\t' -v n="$1" '$1 == n { h = $2 } END { print h }' "$SK_REC" 2>/dev/null || true; }
sk_rec_set(){ mkdir -p "${SK_REC%/*}"
  { awk -F'\t' -v n="$1" '$1 != n' "$SK_REC" 2>/dev/null || true; printf '%s\t%s\n' "$1" "$2"; } > "$SK_REC.tmp" && mv "$SK_REC.tmp" "$SK_REC"; }

# ~/.claude/skills/NAME is a link to the shared copy (or claude isn't here)
sk_linked(){ sk_claude || return 0
  [ -L "$SK_CLAUDE/$1" ] && [ -d "$SK_HOME/$1" ] && [ "$(cd "$SK_CLAUDE/$1" 2>/dev/null && pwd -P)" = "$(cd "$SK_HOME/$1" 2>/dev/null && pwd -P)" ]; }
# the copy your tools load: a folder of its own in ~/.claude/skills (from before npx skills) wins
sk_inst(){ if [ -e "$SK_CLAUDE/$1" ] && ! sk_linked "$1"; then echo "$SK_CLAUDE/$1"
  elif [ -d "$SK_HOME/$1" ]; then echo "$SK_HOME/$1"; fi; }

# the spec's rules (agentskills.io), quick version for the health check. prints the problem
sk_lint(){ local d="$1"
  [ -f "$d/SKILL.md" ] || { echo "no SKILL.md"; return 1; }
  awk -v n="${d##*/}" '
    NR == 1 { if ($0 != "---") { print "SKILL.md has to start with ---"; bad = 1; exit } next }
    /^---[[:space:]]*$/ { closed = 1; exit }
    /^name:/ { v = $0; sub(/^name:[[:space:]]*/, "", v); gsub(/["\047[:space:]]/, "", v); name = v }
    /^description:/ { v = $0; sub(/^description:[[:space:]]*/, "", v); desc = (v != "") }
    /^[A-Za-z_-]+:/ { k = $0; sub(/:.*/, "", k); if (k !~ /^(name|description|license|allowed-tools|metadata|compatibility)$/) extra = extra " " k }
    END { if (bad) exit 1
      if (!closed) { print "the frontmatter never ends (---)"; exit 1 }
      if (name == "") { print "no name"; exit 1 }
      if (name != n) { print "name " name " is not the folder name"; exit 1 }
      if (name !~ /^[a-z0-9]+(-[a-z0-9]+)*$/ || length(name) > 64) { print "the name has to be lowercase letters, digits and single hyphens, 64 at most"; exit 1 }
      if (!desc) { print "no description"; exit 1 }
      if (extra != "") { print "fields the spec does not allow at the top:" extra " (put them under metadata)"; exit 1 } }' "$d/SKILL.md"; }
# the full check: skills-ref, when uv is here (offline it falls back to the quick one)
sk_valid(){ local out
  out="$(sk_lint "$1")" || { echo "$out"; return 1; }
  command -v uvx >/dev/null 2>&1 || return 0
  out="$(uvx --quiet --from "$SK_REF" agentskills validate "$1" 2>&1)" && return 0
  case "$out" in *"Validation failed"*) printf '%s\n' "$out" | sed -n 's/^ *- //p' | head -1; return 1 ;; esac
  return 0; }

# an install from before the record: when the installed copy is a version the repo once
# committed, the repo is just newer. compares git blob hashes against every commit of the skill
sk_was_repo(){ local n="$1" i="$2" p="agents/skills/$1/" mine c
  mine="$( cd "$i" && sk_files . | while IFS= read -r f; do printf '%s %s\n' "$(git hash-object -- "$f")" "$f"; done | LC_ALL=C sort )"
  for c in $(git -C "$DIR" log --format=%H -- "$p" 2>/dev/null); do
    [ "$(git -C "$DIR" ls-tree -r "$c" -- "$p" | awk -v p="$p" '{ t = index($0, "\t"); print $3 " " substr($0, t + 1 + length(p)) }' | LC_ALL=C sort)" = "$mine" ] && return 0
  done
  return 1; }

# every skill to install: name<TAB>folder. the repo's first; a private one with the same name is skipped
sk_sources(){ local s n seen=" "
  for s in "$DIR"/agents/skills/*/ "$SK_PRIV"/*/; do [ -f "$s/SKILL.md" ] || continue
    s="${s%/}"; n="${s##*/}"
    case "$seen" in *" $n "*) continue ;; esac; seen="$seen$n "
    printf '%s\t%s\n' "$n" "$s"; done; return 0; }
sk_from(){ case "$1" in "$DIR"/*) echo "the repo" ;; *) echo "${SK_PRIV/#$HOME/~}" ;; esac; }

# SK_N name, SK_SRC folder, SK_ST state, SK_WHY problem, one entry per skill. states:
#   same · new (not installed) · update (only the source changed) · link (same, but claude reads a
#   copy of its own) · mine (only the installed copy changed) · both (both changed, or no record
#   of the last install) · bad (fails the spec check)
SK_N=(); SK_SRC=(); SK_ST=(); SK_WHY=(); SK_DO=()
sk_scan(){ local n s i r h l st why
  SK_N=(); SK_SRC=(); SK_ST=(); SK_WHY=()
  while IFS=$'\t' read -r n s <&3; do
    i="$(sk_inst "$n")"
    if why="$(sk_lint "$s")"; then why=""; r="$(sk_hash "$s")"
      if [ -z "$i" ]; then st=new
      else h="$(sk_hash "$i")"; l="$(sk_rec "$n")"
        if [ "$h" = "$r" ]; then if sk_linked "$n"; then st=same; else st=link; fi
        elif [ "$h" = "$l" ]; then st=update
        elif [ "$r" = "$l" ]; then st=mine
        elif [ -z "$l" ] && [ "${s#"$DIR"/}" != "$s" ] && sk_was_repo "$n" "$i"; then st=update
        else st=both; fi
      fi
    else st=bad; fi
    SK_N+=("$n"); SK_SRC+=("$s"); SK_ST+=("$st"); SK_WHY+=("$why")
  done 3< <(sk_sources)
  return 0; }
# counts after sk_scan, and the names that need you
sk_count(){ local k; SKC_NEW=0; SKC_UPD=0; SKC_LINK=0; SKC_MINE=0; SKC_BAD=0; SKC_MINE_N=""; SKC_BAD_N=""
  for k in "${!SK_N[@]}"; do case "${SK_ST[$k]}" in
    new) SKC_NEW=$((SKC_NEW + 1)) ;; update) SKC_UPD=$((SKC_UPD + 1)) ;; link) SKC_LINK=$((SKC_LINK + 1)) ;;
    mine|both) SKC_MINE=$((SKC_MINE + 1)); SKC_MINE_N="$SKC_MINE_N ${SK_N[$k]}" ;;
    bad) SKC_BAD=$((SKC_BAD + 1)); SKC_BAD_N="$SKC_BAD_N ${SK_N[$k]}" ;; esac; done; return 0; }

# what happens to each: install, keep (yours stays) or skip
sk_defaults(){ local k; SK_DO=()
  for k in "${!SK_N[@]}"; do case "${SK_ST[$k]}" in
    new|update|link) SK_DO[$k]=install ;; mine|both) SK_DO[$k]=keep ;; *) SK_DO[$k]=skip ;; esac; done; return 0; }

# merge: nvim -d for each file that differs, yours on the left, the source on the right. what you
# leave on the right is what gets installed; files only in yours stay in the backup
sk_merge(){ local k=$1 i s f only=""
  i="$(sk_inst "${SK_N[$k]}")"; s="${SK_SRC[$k]}"
  while IFS= read -r f <&3; do
    if [ ! -f "$s/$f" ]; then only="$only $f"
    elif ! cmp -s "$i/$f" "$s/$f"; then ui_diff "$i/$f" "$s/$f" || return 1; fi
  done 3< <(sk_files "$i")
  [ -n "$only" ] && printf '%s│%s  %s~%s only in yours, kept in the backup:%s\n' "$D" "$X" "$Y" "$X" "$only"
  return 0; }

# installed copies with edits of their own: keep yours, take the source, or merge them in nvim
sk_ask(){ local k n=0 names="" d why from
  sk_scan; sk_defaults
  for k in "${!SK_N[@]}"; do case "${SK_ST[$k]}" in mine|both) n=$((n + 1)); names="$names, ${SK_N[$k]}" ;; esac; done
  [ "$n" -gt 0 ] || return 0
  if [ "$n" -gt 2 ]; then
    ui_menu "$n installed skills have edits the source doesn't: ${names#, }" 0 "Keep all of mine|the other skills install as usual" \
      "Take the source for all|yours saved to ~/.cache/dotfiles first" "Choose each one|keep, take the source, or merge in nv"
    case "$UI_PICK" in
      0) return 0 ;;
      1) for k in "${!SK_N[@]}"; do case "${SK_ST[$k]}" in mine|both) SK_DO[$k]=install ;; esac; done; return 0 ;;
    esac
  fi
  for k in "${!SK_N[@]}"; do case "${SK_ST[$k]}" in mine|both) ;; *) continue ;; esac
    from="$(sk_from "${SK_SRC[$k]}")"
    d="$(diff -r -x __pycache__ -x .dotfiles -x .DS_Store "$(sk_inst "${SK_N[$k]}")" "${SK_SRC[$k]}" 2>/dev/null | grep -c '^[<>]' || true)"
    if [ "${SK_ST[$k]}" = mine ]; then why="you changed the installed copy, $from didn't"
    elif [ -n "$(sk_rec "${SK_N[$k]}")" ]; then why="you and $from both changed it"
    else why="differs from $from, and there's no record of which is newer"; fi
    ui_menu "${SK_N[$k]}: $why"$'\n'"$d lines differ" 0 "Keep mine|nothing changes for ${SK_N[$k]}" \
      "Take the source|${SK_SRC[$k]/#$HOME/~}; yours saved to ~/.cache/dotfiles first" \
      "Merge in nv|left yours, right the source: ]c next change, do / dp copy it, :wqa saves"
    case "$UI_PICK" in 1) SK_DO[$k]=install ;; 2) sk_merge "$k" && SK_DO[$k]=install ;; esac
  done
  return 0; }

# install what was picked: the spec check, a backup of every folder npx skills would replace
# that isn't the same, npx skills once per source, then a record of what's installed
sk_apply(){ local k n s src i t out names agents bak n_ok=0 kept="" bad="" off=""
  bak="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/skills-bak-$STAMP"
  agents="$SK_AGENTS"; sk_claude && agents="claude-code $agents"
  mkdir -p "$HOME/.lavish-axi/excalidraw-libraries"   # whiteboard icon libraries (interactive-diagram sketch)
  [ "${#SK_N[@]}" -gt 0 ] || { echo "no skills found"; return 0; }
  command -v npx >/dev/null 2>&1 || { echo "note: npx isn't installed (brew install node), so no skills were installed"; return 1; }
  # the lists come in on fd 3: uvx and npx read stdin and would eat them
  while IFS= read -r src <&3; do names=""
    for k in "${!SK_N[@]}"; do [ "${SK_SRC[$k]%/*}" = "$src" ] || continue; n="${SK_N[$k]}"
      case "${SK_DO[$k]:-skip}" in keep) kept="$kept $n"; continue ;; install) ;; *) continue ;; esac
      if ! out="$(sk_valid "${SK_SRC[$k]}")"; then bad="$bad $n"; echo "note: $n not installed, it fails the spec check: $out"; continue; fi
      for i in "$SK_HOME/$n" "$SK_CLAUDE/$n"; do
        [ -e "$i" ] || continue
        [ "$i" = "$SK_CLAUDE/$n" ] && sk_linked "$n" && continue
        [ "$(sk_hash "$i")" = "$(sk_hash "${SK_SRC[$k]}")" ] && continue
        t="${i%/skills/*}"; t="${t##*/.}"; mkdir -p "$bak/$t"; cp -RL "$i" "$bak/$t/$n"
      done
      names="$names $n"
    done
    [ -n "$names" ] || continue
    # shellcheck disable=SC2086 # agents and names are lists
    if ! DISABLE_TELEMETRY=1 NO_COLOR=1 npx -y "$SK_NPX" add "$src" -g -a $agents -s $names -y </dev/null; then
      echo "note: npx skills failed for${names}; see the log"; off="$off$names"; continue; fi
    for n in $names; do
      if [ "$(sk_hash "$SK_HOME/$n")" = "$(sk_hash "$src/$n")" ] && sk_linked "$n"; then sk_rec_set "$n" "$(sk_hash "$src/$n")"; n_ok=$((n_ok + 1))
      else off="$off $n"; echo "note: $n: the installed copy doesn't match ${src/#$HOME/~}/$n after installing"; fi
    done
  done 3< <(for k in "${!SK_SRC[@]}"; do echo "${SK_SRC[$k]%/*}"; done | awk '!seen[$0]++')
  [ -n "$kept" ] && echo "note: kept yours:$kept"
  [ -d "$bak" ] && echo "note: the skill copies you had are saved in ${bak/#$HOME/~}"
  [ -n "$off" ] && return 1
  if [ "$n_ok" = 0 ]; then echo "nothing new to install"; else echo "$n_ok installed with npx skills"; fi; }

# the global rules: one AGENTS.md in the repo for every agent tool. claude gets an @import line in
# ~/.claude/CLAUDE.md (your own lines there stay); codex, pi and copilot get a link. opencode is
# left out for now: a file of its own would stop it reading ~/.claude/CLAUDE.md
RL_SRC="$DIR/agents/AGENTS.md"
RL_START="<!-- >>> dotfiles >>> -->"; RL_END="<!-- <<< dotfiles <<< -->"
rl_targets(){
  sk_claude && printf 'claude\t%s\n' "$HOME/.claude/CLAUDE.md"
  { [ -d "${CODEX_HOME:-$HOME/.codex}" ] || command -v codex >/dev/null 2>&1; } && printf 'codex\t%s\n' "${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
  { [ -d "$HOME/.pi" ] || command -v pi >/dev/null 2>&1; } && printf 'pi\t%s\n' "$HOME/.pi/agent/AGENTS.md"
  { [ -d "$HOME/.copilot" ] || command -v copilot >/dev/null 2>&1; } && printf 'copilot\t%s\n' "$HOME/.copilot/copilot-instructions.md"
  return 0; }
# RL_T tool, RL_F file, RL_ST: ok · new (nothing there) · relink (points at another checkout) · yours
RL_T=(); RL_F=(); RL_ST=(); RL_DO=()
rl_scan(){ local t f l
  RL_T=(); RL_F=(); RL_ST=()
  while IFS=$'\t' read -r t f <&3; do
    if [ "$t" = claude ]; then
      if grep -qsxF "@$RL_SRC" "$f"; then l=ok; elif grep -qsF "$RL_START" "$f"; then l=relink; else l=new; fi
    elif [ -L "$f" ]; then l="$(readlink "$f")"
      if [ "$l" = "$RL_SRC" ]; then l=ok
      elif [ ! -e "$f" ] || { [ "${l%/agents/AGENTS.md}" != "$l" ] && [ -f "${l%/agents/AGENTS.md}/install.sh" ]; }; then l=relink
      else l=yours; fi
    elif [ -e "$f" ]; then l=yours
    else l=new; fi
    RL_T+=("$t"); RL_F+=("$f"); RL_ST+=("$l")
  done 3< <(rl_targets)
  return 0; }
# a tool with rules of its own: keep them, replace them with the link, or merge them first
rl_ask(){ local k n
  rl_scan; RL_DO=()
  for k in "${!RL_T[@]}"; do case "${RL_ST[$k]}" in new|relink) RL_DO[$k]=link ;; *) RL_DO[$k]=keep ;; esac; done
  for k in "${!RL_T[@]}"; do [ "${RL_ST[$k]}" = yours ] || continue
    n="$(grep -cv '^[[:space:]]*$' "${RL_F[$k]}" 2>/dev/null || true)"
    ui_menu "${RL_T[$k]} has rules of its own: ${RL_F[$k]/#$HOME/~} (${n:-0} lines)" 0 \
      "Keep yours|${RL_T[$k]} won't read the shared AGENTS.md" \
      "Replace it|yours saved to ~/.cache/dotfiles, then a link to the repo's" \
      "Merge in nv|left yours, right the repo's. the right side is public: nothing private"
    case "$UI_PICK" in 1) RL_DO[$k]=link ;; 2) ui_diff "${RL_F[$k]}" "$RL_SRC" && RL_DO[$k]=link ;; esac
  done
  return 0; }
rl_apply(){ local k f t bak="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/rules-bak-$STAMP" names="" kept=""
  [ -f "$RL_SRC" ] || { echo "note: $RL_SRC is missing"; return 1; }
  for k in "${!RL_T[@]}"; do f="${RL_F[$k]}"; t="${RL_T[$k]}"
    case "${RL_DO[$k]:-keep}" in link) ;; *) [ "${RL_ST[$k]}" = yours ] && kept="$kept $t"; continue ;; esac
    mkdir -p "${f%/*}"
    if [ "$t" = claude ]; then put_block "$f" "$RL_START" "$RL_END" "@$RL_SRC" >/dev/null
    else
      if [ -e "$f" ] && [ ! -L "$f" ]; then mkdir -p "$bak/$t"; cp -p "$f" "$bak/$t/"; echo "note: your old ${f/#$HOME/~} is saved in ${bak/#$HOME/~}/$t"; fi
      rm -f "$f"; ln -s "$RL_SRC" "$f"
    fi
    names="$names, $t"
  done
  [ -n "$kept" ] && echo "note: kept the rules of their own:$kept (they don't read agents/AGENTS.md)"
  if [ -z "$names" ]; then echo "nothing to link"; else echo "rules linked for ${names#, }"; fi; }

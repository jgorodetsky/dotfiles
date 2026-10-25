#!/usr/bin/env zsh
# adopt.zsh - sorts the lines a machine already has in ~/.zshrc (or ~/.zprofile) against this
# repo. each piece is tried in a sandbox shell that has already loaded the repo's version:
#   changes nothing                 -> dup: the repo already does it, so it can go
#   only adds things                -> mine: moves to ~/.zshrc.local, which loads last
#   adds an alias the repo has under another name -> twin: you pick
#   changes something the repo set  -> clash: you pick; by default the repo's keeps winning
# it only works out the plan and writes files. install.sh draws the screens and asks.
#   adopt.zsh --summary FILE   four counts: dup mine twin clash
#   adopt.zsh --plan FILE      one tab-separated row per piece: n kind short danger note line
#   adopt.zsh --list FILE      the plan grouped for reading (install.sh's picker panel)
#   adopt.zsh --apply FILE [--overwrite] [--drop n,n] [--mine n,n] [--off n,n] [--dry] [--no-check]
#       merge (or overwrite: loader only) and print what happened as tab-separated rows.
#       --drop leaves pieces out, --mine lets yours win a clash, --off keeps a piece commented out,
#       --dry writes nothing, --no-check skips loading the shell both ways to compare

# sandbox: runs in its own zsh, loads the repo, then tries each piece
if [[ $1 == --sandbox ]]; then
  # args: repo-rc-files... -- unit-files...
  # prints one line per unit: <index> <same|adds|twin|changes> <what>
  _adopt_skip() { [[ $1 == (_B_*|_adopt*|PWD|OLDPWD|SHLVL|_|RANDOM|SECONDS|LOGCHECK|WATCH|WATCHFMT|zle_*|ZLE_*|i|k|n|d|u|b|v|add|chg|twin) ]] }
  _adopt_snap() {
    typeset -gA _B_alias _B_func _B_par; typeset -ga _B_path
    _B_alias=("${(@kv)aliases}"); _B_func=("${(@kv)functions}"); _B_path=($path)
    local n; for n in ${(k)parameters}; do
      [[ ${parameters[$n]} == *special* ]] && continue; _adopt_skip $n && continue
      _B_par[$n]="${(P)n}"; done
  }
  _adopt_try() { # $1 = index, $2 = file with the unit's code
    local i=$1 u=$2
    ( eval "$(<$u)" </dev/null >/dev/null 2>&1
      local -a add chg; local k n d
      for k in ${(k)aliases}; do
        if (( ! ${+_B_alias[$k]} )); then add+=("alias $k")
        elif [[ "${(j: :)${(z)aliases[$k]}}" != "${(j: :)${(z)_B_alias[$k]}}" ]]; then chg+=("alias $k"); fi
      done
      for k in ${(k)_B_alias}; do (( ${+aliases[$k]} )) || chg+=("alias $k"); done
      for k in ${(k)functions}; do
        if (( ! ${+_B_func[$k]} )); then add+=("$k()")
        elif [[ $functions[$k] != $_B_func[$k] ]]; then chg+=("$k()"); fi
      done
      for n in ${(k)parameters}; do
        [[ ${parameters[$n]} == *special* ]] && continue; _adopt_skip $n && continue
        if (( ! ${+_B_par[$n]} )); then add+=("\$$n")
        elif [[ "${(P)n}" != "$_B_par[$n]" ]]; then
          # colon lists (INFOPATH, MANPATH...) count as sets, like PATH
          if [[ ${(P)n} == *:* || $_B_par[$n] == *:* ]] &&
             [[ ${(j.:.)${(ou)${(s.:.)${(P)n}}:#}} == ${(j.:.)${(ou)${(s.:.)_B_par[$n]}:#}} ]]; then :
          else chg+=("\$$n"); fi
        fi
      done
      # PATH counts as a set: the repo's own order wins either way
      for d in $path; do (( ${_B_path[(Ie)$d]} )) || add+=("PATH ${d/#$HOME/~}"); done
      for d in $_B_path; do (( ${path[(Ie)$d]} )) || chg+=("PATH -${d/#$HOME/~}"); done
      # a new alias that runs exactly what one of the repo's aliases runs
      local -a twin; local b v
      for k in ${(k)aliases}; do (( ${+_B_alias[$k]} )) && continue
        v="${(j: :)${(z)aliases[$k]}}"
        for b in ${(k)_B_alias}; do [[ "${(j: :)${(z)_B_alias[$b]}}" == "$v" ]] && twin+=("$b"); done
      done
      if (( $#chg )); then print -r -- "$i changes ${(j:, :)chg}"
      elif (( $#twin )); then print -r -- "$i twin ${twin[1]}"
      elif (( $#add )); then print -r -- "$i adds ${(j:, :)add}"
      else print -r -- "$i same"; fi )
  }
  shift; typeset -a _adopt_rc _adopt_units
  while [[ $# -gt 0 && $1 != -- ]]; do _adopt_rc+=("$1"); shift; done; shift
  _adopt_units=("$@")
  for _adopt_f in $_adopt_rc; do [[ -f $_adopt_f ]] && source "$_adopt_f" </dev/null >/dev/null 2>&1; done
  "_adopt_snap"
  for _adopt_f in $_adopt_units; do "_adopt_try" "${_adopt_f:t:r}" "$_adopt_f"; done
  exit 0
fi

# main
SELF=${0:A}
emulate -L zsh
setopt extended_glob
MODE=${1:-} RC=${2:-}
[[ $MODE == (--summary|--plan|--list|--apply) && -n $RC ]] || { print -u2 "usage: adopt.zsh --summary|--plan|--list|--apply FILE"; exit 2 }
shift 2
OVERWRITE=0 DRY=0 CHECK=1; typeset -A DROP ACTIVE OFF
while (( $# )); do case $1 in
  --overwrite) OVERWRITE=1 ;; --dry) DRY=1 ;; --no-check) CHECK=0 ;;
  --drop) for k in ${(s:,:)2}; do DROP[$k]=1; done; shift ;;
  --mine) for k in ${(s:,:)2}; do ACTIVE[$k]=1; done; shift ;;
  --off)  for k in ${(s:,:)2}; do OFF[$k]=1; done; shift ;;
  *) print -u2 "adopt.zsh: unknown $1"; exit 2 ;;
esac; shift; done
[[ -f $RC ]] || { [[ $MODE == --summary ]] && print 0 0 0 0; exit 0 }
REPO=${SELF:h:h} NAME=${RC:t} STAMP=$(date +%Y%m%d%H%M%S)
LOCAL=$HOME/$NAME.local
MARK_START="# >>> dotfiles >>>" MARK_END="# <<< dotfiles <<<"
HEADER="# shared shell setup loads from the dotfiles repo below; this machine only: ${LOCAL/#$HOME/~}"
if [[ -t 1 && $MODE == --list ]]; then G=$'\e[32m' R=$'\e[31m' Y=$'\e[33m' C=$'\e[36m' D=$'\e[2m' B=$'\e[1m' X=$'\e[0m'
else G= R= Y= C= D= B= X=; fi
TMP=$(mktemp -d "${TMPDIR:-/tmp}/adopt.XXXXXX"); trap 'rm -rf "$TMP"' EXIT

# the repo files a login shell loads before this one, plus what this machine already keeps local
typeset -a BASE
case $NAME in
  .zprofile) BASE=($REPO/shell/.zprofile $HOME/.zprofile.local) ;;
  .zshrc)    BASE=($REPO/shell/.zprofile $HOME/.zprofile.local $REPO/shell/.zshrc) ;;
  *) print -u2 "adopt.zsh: only .zshrc and .zprofile"; exit 2 ;;
esac

# split the file into pieces: a comment stays with the code under it
typeset -a UNIT KIND WHY
NL=$'\n'
add_unit() { UNIT+=("$1"); KIND+=("$2"); WHY+=("") }
complete() { # does $1 parse as whole commands? (defines a throwaway function, runs nothing)
  [[ $1 == *[^\\]\\ || $1 == \\ ]] && return 1
  eval "_adopt_parse() {"$'\n'"$1"$'\n'"}" 2>/dev/null
}
kind_of() {
  local -a ls=("${(@f)1}"); local first=$ls[1]
  case $first in
    (alias\ *) print alias ;;
    (source\ *|.\ *) print source ;;
    (eval\ \"\$\(*(shellenv|init|activate|hook|env)*) print eval ;;
    (export\ *|typeset\ *|declare\ *|[A-Za-z_][A-Za-z0-9_]#(|\[*\])(|+)=*) print var ;;
    (function\ *|[A-Za-z_][A-Za-z0-9_:.-]#[[:space:]]#\(\)*) print func ;;
    (*) print other ;;
  esac
}
lines=("${(@f)$(<$RC)}")
typeset -a pending
i=1
while (( i <= $#lines )); do
  l=$lines[i]
  if [[ $l == $MARK_START ]]; then
    text=$l; while (( i < $#lines )) && [[ $lines[i] != $MARK_END ]]; do (( i++ )); text+=$'\n'$lines[i]; done
    (( $#pending )) && { add_unit "${(F)pending}" note; pending=() }
    add_unit "$text" block; (( i++ )); continue
  fi
  if [[ $l == '# >>> '*' >>>' ]]; then   # another installer's marked block (conda, nvm...): one piece
    end=${${l/\# >>> /# <<< }/% >>>/ <<<}
    text=$l; while (( i < $#lines )) && [[ $lines[i] != $end ]]; do (( i++ )); text+=$'\n'$lines[i]; done
    add_unit "${(F)pending:+${(F)pending}$NL}$text" other; pending=(); (( i++ )); continue
  fi
  if [[ $l == $HEADER ]]; then (( i++ )); continue; fi   # ours, written fresh each time
  if [[ -z ${l//[[:space:]]/} ]]; then
    (( $#pending )) && { add_unit "${(F)pending}" note; pending=() }
    (( i++ )); continue
  fi
  if [[ $l == [[:space:]]#\#* ]]; then pending+=("$l"); (( i++ )); continue; fi
  text=$l
  while ! complete "$text" && (( i < $#lines )); do (( i++ )); text+=$'\n'$lines[i]; done
  k=$(kind_of "$text")
  add_unit "${(F)pending:+${(F)pending}$NL}$text" $k; pending=(); (( i++ ))
done
(( $#pending )) && add_unit "${(F)pending}" note

# decide each piece
# exact text the repo already has (whitespace-insensitive), for pieces too risky to run
typeset -A REPO_LINES
for f in $REPO/shell/.zprofile $REPO/shell/.zshrc; do
  for l in "${(@f)$(<$f)}"; do [[ -n ${l//[[:space:]]/} ]] && REPO_LINES[${(j: :)${=l}}]=1; done
done
code_of() { local -a l=("${(@f)1}"); l=(${l:#[[:space:]]#\#*}); print -r -- "${(F)l}" }   # the piece minus its comment lines
norm() { print -r -- "${(j: :)${=1}}" }
lines_in() { local -a l=("${(@f)1}"); print $#l }
unsafe() { local t=${1//\'[^\']#\'/}; [[ $t == *'$('* || $t == *'`'* ]] }  # would run a command when defined

# what the repo loads, so `source x` can be matched to the same file
typeset -A SOURCED
for f in "${(@f)$(zsh -f -c "setopt sourcetrace; for f in ${(j: :)${(@q)BASE}}; do [[ -f \$f ]] && source \$f; done" 2>&1 >/dev/null </dev/null | grep -o '^+[^:]*')}"; do
  SOURCED[${${f#+}:A}]=1
done

typeset -a try; typeset -A TWIN
for n in {1..$#UNIT}; do
  code=$(code_of "$UNIT[n]")
  case $KIND[n] in
    block) WHY[n]="dotfiles block" ;;
    note)  KIND[n]=mine; WHY[n]="a comment" ;;
    source)
      tgt=${${(z)code}[2]}; tgt=${(Q)tgt}
      if ! unsafe "$tgt"; then tgt=${(e)${tgt/#\~/$HOME}}; fi
      if [[ -n $tgt && -n ${SOURCED[${tgt:A}]} ]]; then KIND[n]=dup; WHY[n]="the repo already loads this file"
      else KIND[n]=mine; WHY[n]="loads ${tgt/#$HOME/~}"; fi ;;
    alias|var|func|eval)
      if [[ $(lines_in "$code") -eq 1 && -n ${REPO_LINES[$(norm "$code")]} ]]; then KIND[n]=dup; WHY[n]="same line is in the repo"
      elif [[ $KIND[n] != eval ]] && unsafe "$code"; then KIND[n]=mine; WHY[n]="runs a command, kept as is"
      else print -r -- "$code" > $TMP/$n.unit; try+=($TMP/$n.unit); fi ;;
    other)
      if [[ $(lines_in "$code") -eq 1 && -n ${REPO_LINES[$(norm "$code")]} ]]; then KIND[n]=dup; WHY[n]="same line is in the repo"
      else KIND[n]=mine; WHY[n]="kept as is"; fi ;;
  esac
done
if (( $#try )); then
  for r in "${(@f)$(zsh -f $SELF --sandbox $BASE -- $try 2>/dev/null)}"; do
    n=${r%% *}; rest=${r#* }; verdict=${rest%% *}; what=${rest#$verdict}; what=${what# }
    case $verdict in
      same)    KIND[n]=dup;      WHY[n]="the repo already does this" ;;
      twin)    KIND[n]=twin;     TWIN[$n]=$what; WHY[n]="the repo's $what runs the same" ;;
      adds)    KIND[n]=mine;     WHY[n]="adds $what" ;;
      changes) KIND[n]=conflict; WHY[n]="changes $what" ;;
    esac
  done
fi
DANGER='reset --hard|rm -rf|push (-f|--force)( |$|'"'"')|clean -[a-z]*f|checkout -- \.'
for n in {1..$#UNIT}; do
  [[ $KIND[n] == (alias|var|func|eval) ]] && { KIND[n]=mine; WHY[n]="could not be tried, kept as is" }
done

if [[ $MODE == --summary ]]; then
  c=(0 0 0 0); for k in $KIND; do case $k in dup) (( c[1]++ )) ;; mine) (( c[2]++ )) ;; twin) (( c[3]++ )) ;; conflict) (( c[4]++ )) ;; esac; done
  print $c; exit 0
fi

# what the repo's aliases run, to show next to a clash or a twin
typeset -A RALIAS
for l in "${(@f)$(zsh -f -c "for f in ${(j: :)${(@q)BASE}}; do [[ -f \$f ]] && source \$f; done </dev/null >/dev/null 2>&1; alias -L" 2>/dev/null)}"; do
  [[ $l == alias\ * ]] || continue; l=${l#alias }; l=${l#-- }; RALIAS[${l%%=*}]=${(Q)l#*=}
done

show() { # the piece's first line of code, and how long it is
  local -a c=("${(@f)$(code_of "$1")}") all=("${(@f)1}"); local s=$c[1]
  (( $#c > 1 )) && s="$s ... ($#c lines)"; [[ -z $s ]] && s=$all[1]
  print -r -- "${s[1,70]}"
}
short() { # a name small enough for the buckets: the alias, $VAR, PATH dir, source file, func()
  local -a c=("${(@f)$(code_of "$1")}") all=("${(@f)1}"); local f=$c[1] v
  case $f in
    ('') print -r -- "# ${${all[1]#\#}# }" | cut -c1-18 ;;
    (alias\ *) f=${f#alias }; f=${f#-- }; print -r -- "${f%%=*}" ;;
    ((export\ |)PATH=*|path=*|path+=*)
      v=${f#*=}; v=${${v//\"/}//\'/}; v=${v%%:*}; v="${v/\$HOME/~}"; v="${v/\$\{HOME\}/~}"; v="${v/#$HOME/~}"
      print -r -- "PATH ${v#\(}" ;;
    (export\ *|typeset\ *|declare\ *) f=${f#* }; f=${f#-[a-zA-Z]# }; print -r -- "\$${f%%=*}" ;;
    ([A-Za-z_]*=*) print -r -- "\$${f%%=*}" ;;
    (source\ *|.\ *) v=${${(z)f}[2]}; print -r -- "source ${${(Q)v}:t}" ;;
    (eval\ *) v=${f#*\$\(}; print -r -- "eval ${v%% *}" ;;
    (function\ *) v=${f#function }; print -r -- "${v%%[ (]*}()" ;;
    ([A-Za-z_]*\(\)*) print -r -- "${f%%\(*}()" ;;
    (*) print -r -- "${f[1,18]}" ;;
  esac
}
note_of() { # why it landed where it did
  local n=$1 an
  case $KIND[n] in
    twin) print -r -- "the repo's ${TWIN[$n]} runs the same" ;;
    conflict) an=${${WHY[n]#changes alias }%%,*}
      if [[ $WHY[n] == "changes alias "* && -n ${RALIAS[$an]} ]]; then print -r -- "the repo's $an runs: ${RALIAS[$an]}"
      else print -r -- "$WHY[n]"; fi ;;
    *) print -r -- "$WHY[n]" ;;
  esac
}
danger() { [[ $UNIT[$1] =~ $DANGER ]] && print 1 || print 0 }

typeset -a G_DUP G_MINE G_TWIN G_CLASH
for n in {1..$#UNIT}; do case $KIND[n] in
  dup) G_DUP+=($n) ;; mine) G_MINE+=($n) ;; twin) G_TWIN+=($n) ;; conflict) G_CLASH+=($n) ;; esac; done
TOTAL=$(( $#G_DUP + $#G_MINE + $#G_TWIN + $#G_CLASH ))

if [[ $MODE == --plan ]]; then
  for n in {1..$#UNIT}; do [[ $KIND[n] == (dup|mine|twin|conflict) ]] || continue
    print -r -- "$n	$KIND[n]	$(short "$UNIT[n]")	$(danger $n)	$(note_of $n)	$(show "$UNIT[n]")"
  done
  exit 0
fi

if [[ $MODE == --list ]]; then
  group() { # LABEL WHERE-IT-GOES COLOR INDEX...
    local label=$1 dest=$2 col=$3 n flag; shift 3; (( $# )) || return 0
    printf "  ${col}%-24s${X} → %s\n" "$label ($#)" "$dest"
    for n in "$@"; do
      flag=""; [[ $(danger $n) == 1 ]] && flag="  ${R}⚠ destructive${X}"
      printf "      %-62s ${D}%s${X}%s\n" "$(show "$UNIT[n]" | cut -c1-60)" "$( [[ $KIND[n] == (twin|conflict) ]] && note_of $n)" "$flag"
    done
  }
  (( TOTAL )) || { print "  ${G}✓${X} ${B}${RC/#$HOME/~}${X}  only the loader, nothing to sort"; exit 0 }
  print "\n  ${B}${RC/#$HOME/~}${X}  $TOTAL line(s) besides the loader\n"
  group "same as the repo" "deleted (kept in the backup)" "$D" $G_DUP
  group "only yours" "moved to ${LOCAL/#$HOME/~}" "$C" $G_MINE
  group "same job, two names" "you pick" "$Y" $G_TWIN
  group "clash with the repo" "you pick (the repo's wins unless you say)" "$Y" $G_CLASH
  exit 0
fi

# --apply: build the new files (a file that's already tidy is left alone)
(( TOTAL )) || { print -r -- "tidy	${RC/#$HOME/~}"; exit 0 }
new_rc=$TMP/rc; new_local=$TMP/local; typeset -a moved_names
{ print -r -- "$HEADER"
  for n in {1..$#UNIT}; do [[ $KIND[n] == block ]] && print -r -- "$UNIT[n]"; done } > $new_rc
moved=0
{ [[ -f $LOCAL ]] && print -r -- "$(<$LOCAL)"
  (( OVERWRITE )) || for n in {1..$#UNIT}; do
    [[ $KIND[n] == (mine|twin|conflict) && -z $DROP[$n] ]] || continue
    (( moved++ == 0 )) && { [[ -f $LOCAL ]] && print; print "# from ${RC/#$HOME/~}, sorted by dotfiles install.sh on $(date +%F)" }
    moved_names+=("$(short "$UNIT[n]")")
    if [[ -n $OFF[$n] ]]; then
      print "# turned off because it can destroy work; uncomment to use it again"
      print -r -- "${(F)${(@f)UNIT[n]/#/# }}"
    elif [[ $KIND[n] == conflict && -z $ACTIVE[$n] ]]; then
      print "# the repo sets this differently and wins; uncomment to use yours instead"
      print -r -- "${(F)${(@f)UNIT[n]/#/# }}"
    else print -r -- "$UNIT[n]"; fi
  done } > $new_local
for f in $new_rc $new_local; do
  zsh -n $f 2>$TMP/err || { print -r -- "error	the result wouldn't parse, nothing changed: $(head -1 $TMP/err)"; exit 1 }
done
print -r -- "rc	${RC/#$HOME/~}	only the loader"
(( moved )) && print -r -- "local	${LOCAL/#$HOME/~}	$moved	${(j:, :)moved_names}"
(( TOTAL - moved )) && print -r -- "gone	$(( TOTAL - moved ))"

# load the shell both ways and compare what it defines
if (( CHECK )); then
  snapshot() { # $1 = home dir holding the rc files to load
    HOME=$1 zsh -f -c '
      for f in ~/.zprofile ~/.zshrc; do [[ -f $f ]] && source $f; done </dev/null >/dev/null 2>&1
      alias -L | sort | sed "s/^/alias  /"
      for f in ${(ok)functions}; do print -r -- "func   $f ${functions[$f]//$'"'"'\n'"'"'/ }"; done
      typeset -x | grep -vE "^(export )?(PWD|OLDPWD|SHLVL|_|PATH|STARSHIP_SESSION_KEY|STARSHIP_START_TIME)=" | sed "s/^/env    /"
      setopt | sed "s/^/opt    /"
      typeset -A won; for d in $path; do for c in $d/*(N*:t); do [[ -z $won[$c] ]] && won[$c]=$d; done; done
      for c in ${(ok)won}; do print -r -- "cmd    $c -> $won[$c]"; done
      print -l $path | sed "s/^/path   /"' 2>/dev/null | sed "s|$1|$HOME|g"
  }
  for side in before after; do
    h=$TMP/$side; mkdir -p $h
    for e in $HOME/*(DN); do [[ ${e:t} == (.zshrc|.zprofile|.zshrc.local|.zprofile.local) ]] || ln -sf $e $h/ 2>/dev/null; done
    for f in .zshrc .zprofile .zshrc.local .zprofile.local; do [[ -f $HOME/$f ]] && cp $HOME/$f $h/; done
  done
  cp $new_rc $TMP/after/$NAME; cp $new_local $TMP/after/$NAME.local
  snapshot $TMP/before > $TMP/before.state; snapshot $TMP/after > $TMP/after.state
  typeset -A LBL=(alias alias func function env 'env var' opt option cmd command path 'PATH folder')
  changed=0
  for t in alias func env opt cmd path; do
    diff <(grep "^$t " $TMP/before.state | sort -u) <(grep "^$t " $TMP/after.state | sort -u) | grep '^[<>]' | head -8 |
      while IFS= read -r l; do
        [[ $l == '<'* ]] && w=gone || w=new
        l=${l#[<>] }; l=${l#$t }; l=${l##[[:space:]]#}
        print -r -- "change	$LBL[$t]	$w	${l[1,90]}"
      done
  done > $TMP/changes
  if [[ -s $TMP/changes ]]; then cat $TMP/changes
  else print -r -- "same	$(grep -c '^alias ' $TMP/after.state)	$(grep -c '^func ' $TMP/after.state)	$(grep -c '^env ' $TMP/after.state)"; fi
fi

(( DRY )) && exit 0
cp -p $RC $RC.bak-$STAMP; [[ -f $LOCAL ]] && cp -p $LOCAL $LOCAL.bak-$STAMP
cat $new_rc > $RC
(( moved )) && cat $new_local > $LOCAL
undo="cp ${RC/#$HOME/~}.bak-$STAMP ${RC/#$HOME/~}"
if (( moved )); then [[ -f $LOCAL.bak-$STAMP ]] && undo+=" && cp ${LOCAL/#$HOME/~}.bak-$STAMP ${LOCAL/#$HOME/~}" || undo+=" && rm ${LOCAL/#$HOME/~}"; fi
print -r -- "written	${RC/#$HOME/~}.bak-$STAMP"
print -r -- "undo	$undo"

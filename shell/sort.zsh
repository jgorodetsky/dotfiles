#!/usr/bin/env zsh
# sort.zsh - the lines you had in ~/.zshrc and ~/.zprofile besides the loader, in the form dott
# reads (adopt.zsh does the work). --check only reads.
#   sort.zsh --check   exit 0: nothing to sort. exit 1: lines to sort (first line what, second the fix)
#   sort.zsh --plan    what --apply does, one line each
#   sort.zsh --apply   merge: what the repo already does goes, your own lines move to ~/.zshrc.local or
#                      ~/.zprofile.local (they load last), a line that clashes with the repo stays there
#                      commented out. a backup of each file goes next to it.
emulate -L zsh
here=${0:A:h}
typeset -a files desc
total=0
for f in .zprofile .zshrc; do
  [[ -s $HOME/$f ]] || continue
  c=($(zsh $here/adopt.zsh --summary $HOME/$f 2>/dev/null))
  (( $#c == 4 )) || continue
  n=$(( c[1] + c[2] + c[3] + c[4] ))
  (( n )) || continue
  files+=($f); total=$(( total + n ))
  desc+=("~/$f: $n lines: $c[1] the repo already does, $c[2] only yours, $c[3] twins of the repo's aliases, $c[4] clashes")
done
case ${1:-} in
  --check)
    if (( total )); then
      names=(); for f in $files; do names+=("~/$f"); done
      print -r -- "$total lines in ${(j: and :)names} to sort"; print "sort them"; exit 1
    fi
    print "~/.zshrc and ~/.zprofile hold only the loader"; exit 0 ;;
  --plan)
    for d in $desc; do print -r -- "$d"; done
    print "drop what the repo already does; move your own lines to the .local file next to it (it loads last)"
    print "a line that clashes with the repo: the repo's wins, yours stays commented out; a backup goes next to each file" ;;
  --apply)
    for f in $files; do
      out=$(zsh $here/adopt.zsh --apply $HOME/$f --no-check) || { print -r -- "$out"; exit 1 }
      print -r -- "$out" | grep -q '^error' && { print -r -- "$out"; exit 1 }
      print -r -- "~/$f sorted. undo: $(print -r -- "$out" | awk -F'\t' '$1 == "undo" { print $2 }')"
    done ;;
  *) print -u2 "usage: sort.zsh --check|--plan|--apply"; exit 2 ;;
esac

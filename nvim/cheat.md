# day-one vim

## modes - the one idea that makes vim make sense
  normal mode        where you start. keys are commands, not text
  i                  insert mode: type like a normal editor
  esc                back to normal mode (press it whenever you're lost)
  v / V              select characters / whole lines
  :                  command line (save, quit, run commands)

## moving (normal mode)
  h j k l            left down up right (arrow keys work too)
  w / b              next / previous word
  0 / $              start / end of the line
  gg / G             top / bottom of the file
  ctrl+d / ctrl+u    half a page down / up
  /word then enter   search, then n / N for next / previous

## editing (normal mode)
  x                  delete one character
  dd                 cut the line
  yy                 copy the line
  p                  paste below
  u / ctrl+r         undo / redo
  .                  repeat the last change
  o                  new line below, start typing
  ciw                change the word under the cursor

## save and quit
  cmd+s or :w        save
  :q                 quit (:q! quits without saving)
  :wq                save and quit

## mouse and clipboard work like a mac app
  click, drag to select, scroll. y copies to the mac clipboard, cmd+v pastes

## tables (csv and tsv files)
  tab / shift+tab    next / previous column
  enter              next row
  cif                change this cell
  :CsvViewToggle     table view on / off

## lazyvim keys (space is the leader: press space and wait for the menu)
  space space        find a file
  space /            search text in all files
  space e            file tree
  space f r          recent files
  space ,            switch between open files
  shift+h / shift+l  previous / next open file (tabs along the top)
  space b d          close the current file
  space - / space |  split below / split right
  ctrl+h/j/k/l       move between splits
  ctrl+/             terminal at the bottom
  space g g          lazygit (git in a window)
  gd / K             go to definition / docs for the word under the cursor
  space c a          fix-it suggestions (code actions)
  space c f          format the file
  space l            plugin manager
  space c m          language tools installer (mason)
  space q q          quit everything

## extras from these dotfiles
  space then C       this cheat sheet
  space then u C     pick a color theme with live preview ("ghostty" = your terminal theme)
  :Transparent       see-through background on / off
  :Tutor             the 30-minute interactive lesson built into neovim

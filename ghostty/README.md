# ChessKing - a Ghostty theme

A cyberpunk chessboard terminal theme for [Ghostty](https://ghostty.org): a near-black
board with faint cyan light-squares, dim magenta grid lines, and a large framed king
ghosted in the center. Text is Homebrew neon-green, accents are orange, and the cursor
is a magenta block.

![ChessKing board](chess-king-cyber.png)

## Files (paths from repo root)

| Path | What it is |
|------|-----------|
| `ghostty/themes/ChessKing` | the theme file (palette, foreground, cursor, selection) |
| `ghostty/chess-king-cyber.png` | the chessboard background image (2560x1600) |
| `install.sh` | copies both into your Ghostty config dir and adds the config lines |
| `generator/chess-cyber.html` | the source the background image is rendered from |
| `generator/render.sh` | re-renders the PNG from the HTML (only needed to tweak the board) |

## Requirements

- Ghostty **1.1+** - the `background-image` support this theme uses landed in 1.1.
  The colors alone work on any version; the board is just a background image behind the text.

## Install

```bash
git clone https://github.com/jgorodetsky/dotfiles.git
cd dotfiles
./install.sh
```

Then reload Ghostty: **macOS** `Cmd+Shift+,` / **Linux** `Ctrl+Shift+,` (or restart it).

`install.sh` is idempotent - re-running it won't duplicate anything.

### What install.sh does

1. Copies `ChessKing` into `~/.config/ghostty/themes/`
2. Copies the board PNG into `~/.config/ghostty/`
3. Appends a managed block to `~/.config/ghostty/config`:

```
theme = ChessKing
background-image = ~/.config/ghostty/chess-king-cyber.png
background-image-opacity = 0.6
background-image-position = center
background-image-fit = cover
background-image-repeat = false
```

The `background-image` line is written as a real absolute path for your user.

## Manual install

```bash
mkdir -p ~/.config/ghostty/themes
cp ghostty/themes/ChessKing ~/.config/ghostty/themes/
cp ghostty/chess-king-cyber.png ~/.config/ghostty/
```

Then add the config block above to `~/.config/ghostty/config`, using the absolute path
to the PNG (e.g. `/Users/you/.config/ghostty/chess-king-cyber.png`).

> **macOS note:** Ghostty also reads `~/Library/Application Support/com.mitchellh.ghostty/config`.
> If your config lives there, add the block to that file instead.

## Tuning

- **Background too strong or too faint behind text?** change `background-image-opacity`
  (0.0-1.0). 0.6 is the default.
- **Different text color?** edit `foreground` in `~/.config/ghostty/themes/ChessKing`.
  `cursor-color` is the magenta block; `palette = 6` / `palette = 14` are the orange accents.

## Regenerating the board

The PNG ships pre-rendered. Only needed if you want to change the board itself - edit
`generator/chess-cyber.html`, then:

```bash
./generator/render.sh
```

Re-run `./install.sh` afterwards to copy the new PNG into place.

## Uninstall

Remove the managed block from `~/.config/ghostty/config` (the `>>> ChessKing` /
`<<< ChessKing` marker lines and everything between), then:

```bash
rm ~/.config/ghostty/themes/ChessKing ~/.config/ghostty/chess-king-cyber.png
```

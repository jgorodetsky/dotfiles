# login-shell environment. runs once per login, so PATH can't accumulate.

# keep PATH entries unique even if this file is re-sourced
typeset -U path PATH

# homebrew: prefix, PATH, sbin, MANPATH, INFOPATH, and zsh completion fpath
for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [ -x "$b" ] && { eval "$("$b" shellenv)"; break; }
done

# user-local bins (uv, pipx, native installers)
export PATH="$HOME/.local/bin:$PATH"

# packages installed by brew bundle. install.sh reads this file to build its health-check.
# format per line:  brew|cask "name"   # short description  (install.sh parses both).

tap "hashicorp/tap"
tap "jgorodetsky/ghh"

# core-cli
brew "gh"        # GitHub CLI
brew "jq"        # JSON processor
brew "ripgrep"   # fast code search (rg)
brew "fzf"       # fuzzy finder
brew "tree"      # directory tree
brew "stow"      # symlink manager for dotfiles

# languages
brew "go"        # Go toolchain
brew "ruff"      # Python linter / formatter
brew "hashicorp/tap/terraform"  # Terraform (via HashiCorp tap; removed from core on BUSL relicense)
brew "helm"      # Kubernetes package manager

# tools
brew "ghh"       # git + GitHub workflow (your tap)

# apps
cask "ghostty"                                    # terminal
cask "visual-studio-code", args: { adopt: true }  # editor (adopt an existing install)

# packages installed by brew bundle. install.sh reads this file to build its health-check.
# format per line:  brew|cask "name"   # short description  (install.sh parses both).
# third-party formulae use their full name + trusted: true so homebrew 6+ will load them.

tap "hashicorp/tap"
tap "jgorodetsky/ghh"

# core-cli
brew "gh"        # GitHub CLI
brew "jq"        # JSON processor
brew "ripgrep"   # fast code search (rg)
brew "fzf"       # fuzzy finder
brew "tree"      # directory tree
brew "eza"       # ls with colors + git status
brew "bat"       # cat with syntax highlighting
brew "zoxide"    # smarter cd (z / zi)
brew "tlrc"      # tldr: short real-world examples for any command

# prompt
brew "starship"                 # prompt: git, aws profile, kube context
brew "zsh-autosuggestions"      # gray ghost-text completions from history
brew "zsh-syntax-highlighting"  # red/green command highlighting

# cloud
brew "awscli"          # AWS CLI v2
brew "kubernetes-cli"  # kubectl

# languages
brew "go"        # Go toolchain
brew "ruff"      # Python linter / formatter
brew "hashicorp/tap/terraform", trusted: true  # Terraform (via HashiCorp tap; removed from core on BUSL relicense)
brew "helm"      # Kubernetes package manager

# tools
brew "jgorodetsky/ghh/ghh", trusted: true  # git + GitHub workflow (your tap)

# apps
cask "ghostty"                                    # terminal
cask "visual-studio-code", args: { adopt: true }  # editor (adopt an existing install)

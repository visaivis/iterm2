#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Modern Terminal Configuration - Sandbox Test
# =============================================================================
# Launches an isolated zsh session to preview the config WITHOUT modifying
# your real ~/.zshrc or any system files.
#
# How it works:
#   1. Creates a temp directory as ZDOTDIR (zsh reads config from here)
#   2. Writes a minimal .zshrc that sources our config
#   3. Optionally installs the iTerm2 Dynamic Profile (additive, safe)
#   4. Spawns a new zsh shell using that ZDOTDIR
#   5. Cleans up the temp dir on exit
#
# Prerequisites:
#   - Brew packages must be installed first (run: brew bundle --file=Brewfile)
#   - Powerlevel10k must be installed
#
# Usage:
#   ./test.sh              # Test zsh config in sandboxed shell
#   ./test.sh --install-deps  # Install brew deps first, then test
#   ./test.sh --with-tmux  # Also launch tmux with the test config
#   ./test.sh --profile    # Also install iTerm2 Dynamic Profile

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DEPS=false
WITH_TMUX=false
WITH_PROFILE=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${BLUE}ℹ${NC} $*"; }
ok()    { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC} $*"; }
err()   { echo -e "${RED}✗${NC} $*"; }
header(){ echo -e "\n${BOLD}${CYAN}$*${NC}"; echo -e "${DIM}$(printf '─%.0s' {1..60})${NC}"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-deps) INSTALL_DEPS=true ;;
    --with-tmux)    WITH_TMUX=true ;;
    --profile)      WITH_PROFILE=true ;;
    -h|--help)
      echo -e "${BOLD}Sandbox Test${NC}"
      echo ""
      echo "  ./test.sh                 Launch sandboxed zsh with the config"
      echo "  ./test.sh --install-deps  Install brew dependencies first"
      echo "  ./test.sh --with-tmux     Also start tmux with the test config"
      echo "  ./test.sh --profile       Also install iTerm2 Dynamic Profile"
      echo ""
      echo "The sandboxed shell is fully isolated — your ~/.zshrc is not touched."
      echo "Type 'exit' to return to your normal shell."
      exit 0
      ;;
    *) err "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

# =============================================================================
# Install dependencies if requested
# =============================================================================

if $INSTALL_DEPS; then
  header "Installing Homebrew dependencies"
  brew bundle --file="$SCRIPT_DIR/Brewfile" --no-lock || {
    warn "Some packages may have failed to install"
  }
  ok "Dependencies installed"
fi

# =============================================================================
# Check prerequisites
# =============================================================================

header "Checking prerequisites"

missing=()
for cmd in eza bat fd rg zoxide fzf; do
  if ! command -v "$cmd" &>/dev/null; then
    missing+=("$cmd")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  warn "Missing tools: ${missing[*]}"
  warn "Run with --install-deps to install them, or: brew bundle --file=$SCRIPT_DIR/Brewfile"
  echo ""
  if ! command -v fzf &>/dev/null; then
    err "fzf is required for the test. Aborting."
    exit 1
  fi
fi

# Check for p10k
if ! command -v powerlevel10k &>/dev/null && [[ ! -f /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme ]]; then
  warn "Powerlevel10k not found. Prompt may not render correctly."
fi

ok "Prerequisites checked"

# =============================================================================
# Clone fzf-tab if not present
# =============================================================================

fzf_tab_dir="$SCRIPT_DIR/vendor/fzf-tab"
if [[ ! -d "$fzf_tab_dir" ]]; then
  info "Cloning fzf-tab..."
  mkdir -p "$SCRIPT_DIR/vendor"
  git clone --depth 1 https://github.com/Aloxaf/fzf-tab.git "$fzf_tab_dir" 2>/dev/null || {
    warn "Could not clone fzf-tab. Tab completion will use defaults."
  }
fi

# =============================================================================
# Install iTerm2 Dynamic Profile (if requested)
# =============================================================================

if $WITH_PROFILE; then
  header "Installing iTerm2 Dynamic Profile"
  profile_dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
  profile_dest="$profile_dir/modern-dark.json"
  mkdir -p "$profile_dir"
  cp "$SCRIPT_DIR/config/iterm2/modern-dark.json" "$profile_dest"
  ok "Installed 'Modern Dark' profile"
  info "Switch to it: iTerm2 → Settings → Profiles → Modern Dark"
  info "To remove later: rm \"$profile_dest\""
fi

# =============================================================================
# Create sandboxed ZDOTDIR
# =============================================================================

header "Setting up sandbox"

SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT

# Write a minimal .zshrc for the sandbox
cat > "$SANDBOX/.zshrc" << ZSHRC_EOF
# Sandboxed test shell — your real ~/.zshrc is NOT loaded
# Type 'exit' to return to your normal shell

# Load p10k instant prompt (from the real cache, read-only)
if [[ -r "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh" ]]; then
  source "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh"
fi

# Homebrew path
export PATH="/opt/homebrew/bin:\$PATH"

# Load p10k theme
if [[ -f /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme ]]; then
  source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
fi

# Load user's p10k config (read-only, for their existing segments)
[[ -f "\$HOME/.p10k.zsh" ]] && source "\$HOME/.p10k.zsh"

# Load our modern terminal config
export MODERN_TERMINAL_DIR="$SCRIPT_DIR/config/zsh"
source "$SCRIPT_DIR/config/zsh/init.zsh"

# Sandbox indicator in prompt
echo ""
echo -e "\033[1;36m╔══════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║\033[0m  \033[1mSandboxed Terminal Config Test\033[0m                       \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m  Your real ~/.zshrc is NOT loaded.                   \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m  Type \033[1;33mexit\033[0m to return to your normal shell.            \033[1;36m║\033[0m"
echo -e "\033[1;36m╚══════════════════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[2mThings to try:\033[0m"
echo -e "  \033[1mls\033[0m             — eza with icons"
echo -e "  \033[1mcat README.md\033[0m  — bat with syntax highlighting"
echo -e "  \033[1mCtrl+R\033[0m         — fuzzy history search"
echo -e "  \033[1mTab\033[0m            — fuzzy completion"
echo -e "  \033[1mai-workspace\033[0m   — tmux AI layout"
echo -e "  \033[1mtls\033[0m            — list tmux sessions"
echo ""
ZSHRC_EOF

ok "Sandbox created at: $SANDBOX"

# =============================================================================
# Launch
# =============================================================================

if $WITH_TMUX; then
  header "Launching sandboxed zsh inside tmux"
  info "tmux prefix is Ctrl+a (not Ctrl+b)"
  info "Type 'exit' in the shell, then 'tmux kill-server' to fully exit"
  echo ""
  ZDOTDIR="$SANDBOX" tmux -f "$SCRIPT_DIR/config/tmux/tmux.conf" new-session -s test-config "ZDOTDIR=$SANDBOX zsh"
else
  header "Launching sandboxed zsh"
  info "Type 'exit' to return to your normal shell"
  echo ""
  ZDOTDIR="$SANDBOX" zsh
fi

header "Sandbox exited"
ok "Your real shell is unchanged. No cleanup needed."

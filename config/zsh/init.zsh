# Modern Terminal Configuration - Entry Point
# This file is sourced from ~/.zshrc via:
#   [[ -f ~/.modern-terminal/init.zsh ]] && source ~/.modern-terminal/init.zsh
#
# Each module is independent and can be commented out to disable.

MODERN_TERMINAL_DIR="${0:A:h}"

# 1. Completion system (must come before fzf-tab)
source "$MODERN_TERMINAL_DIR/plugins.zsh"

# 2. fzf configuration and keybindings
source "$MODERN_TERMINAL_DIR/fzf.zsh"

# 3. Modern CLI aliases (eza, bat, fd, ripgrep, zoxide)
source "$MODERN_TERMINAL_DIR/aliases.zsh"

# 4. Powerlevel10k theme (source if not already loaded by user's .zshrc)
if [[ -z "$POWERLEVEL9K_VERSION" ]]; then
  _p10k_theme="${HOMEBREW_PREFIX:-/opt/homebrew}/share/powerlevel10k/powerlevel10k.zsh-theme"
  if [[ -f "$_p10k_theme" ]]; then
    source "$_p10k_theme"
  fi
  unset _p10k_theme
fi

# 4a. Powerlevel10k configuration (user's or our bundled default)
# The p10k theme does not auto-source this; it must be loaded explicitly.
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# 5. Powerlevel10k overlay (theme-matched colors, transient prompt)
source "$MODERN_TERMINAL_DIR/p10k-overlay.zsh"

# 6. tmux aliases and AI workspace layouts
source "$MODERN_TERMINAL_DIR/tmux.zsh"

# 7. iTerm2 shell integration (must be near the end)
source "$MODERN_TERMINAL_DIR/iterm2-integration.zsh"

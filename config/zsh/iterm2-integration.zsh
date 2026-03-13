# iTerm2 Shell Integration
# Enables command marks, captured output, and automatic profile switching.
# Only loads when running inside iTerm2 (not in other terminals or tmux plain mode).

if [[ "$TERM_PROGRAM" == "iTerm.app" || -n "$ITERM_SESSION_ID" ]]; then
  ITERM2_INTEGRATION="$HOME/.iterm2_shell_integration.zsh"
  if [[ -f "$ITERM2_INTEGRATION" ]]; then
    source "$ITERM2_INTEGRATION"
  fi
fi

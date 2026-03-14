# iTerm2 Shell Integration
# p10k has native iTerm2 shell integration (command marks, captured output,
# automatic profile switching) enabled via POWERLEVEL9K_TERM_SHELL_INTEGRATION.
# Do NOT source ~/.iterm2_shell_integration.zsh alongside p10k — doing so
# injects a visible '>' caret before the prompt.
#
# POWERLEVEL9K_TERM_SHELL_INTEGRATION is set in p10k-overlay.zsh.
#
# Utilities like `imgcat` and `it2dl` that ship with the standalone integration
# can still be loaded separately if needed by sourcing only the utilities file:
#   source "$HOME/.iterm2_shell_integration.zsh" --only-utilities

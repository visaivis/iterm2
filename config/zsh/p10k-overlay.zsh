# Powerlevel10k Overlay
# Applied after ~/.p10k.zsh to add enhancements.
# Color theming is owned by the official Dracula p10k config (p10k-default.zsh).
# This file only adds behaviour that isn't covered by the base config.

# Only apply if p10k is loaded
if (( ${+functions[powerlevel10k]} )) || [[ -n "$POWERLEVEL9K_LEFT_PROMPT_ELEMENTS" ]]; then

  # iTerm2 shell integration disabled to prevent mark indicators (arrows)
  # appearing in the left gutter on every prompt line.
  # Re-enable by setting POWERLEVEL9K_TERM_SHELL_INTEGRATION=true
  typeset -g POWERLEVEL9K_TERM_SHELL_INTEGRATION=false

  # --- Transient prompt ---
  # Collapses accepted commands to a minimal one-line prompt, keeping the
  # scrollback clean. 'same-dir' only collapses within the same directory.
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=same-dir

fi

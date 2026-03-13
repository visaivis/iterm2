# Powerlevel10k Overlay
# Applied after the user's own .p10k.zsh to add modern terminal enhancements.
# These settings are safe to apply on top of any p10k configuration.

# Only apply if p10k is loaded
if (( ${+functions[powerlevel10k]} )) || [[ -n "$POWERLEVEL9K_LEFT_PROMPT_ELEMENTS" ]]; then

  # --- Transient prompt ---
  # Collapses previous prompts to a minimal "❯", creating visual block separation.
  # This is the closest approximation to block-based terminal output.
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=same-dir

  # --- Command execution time ---
  # Show how long commands took (like modern terminal status)
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=1
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='#f7ca88'  # Yellow

  # --- Theme-matched colors ---
  typeset -g POWERLEVEL9K_DIR_FOREGROUND='#7cafc2'             # Blue accent for directory
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND='#a1b56c'       # Green for clean git
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='#f7ca88'    # Yellow for modified
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='#ab4642'   # Red for untracked
  typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND='#a1b56c'       # Green for success
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND='#ab4642'    # Red for error

  # --- Instant prompt compatibility ---
  # These settings are safe to set after instant prompt has already rendered.
  # The first prompt may look slightly different; subsequent prompts will use these.

fi

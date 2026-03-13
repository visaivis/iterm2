# Modern CLI Aliases
# Only aliases commands if the replacement tool is installed.
# Original commands remain accessible via their full path (e.g., /bin/ls).

# --- eza (ls replacement) ---
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --group-directories-first --git --time-style=relative'
  alias la='eza -la --icons --group-directories-first --git --time-style=relative'
  alias lt='eza --tree --icons --level=2 --group-directories-first'
  alias tree='eza --tree --icons --group-directories-first'
fi

# --- bat (cat replacement) ---
if command -v bat &>/dev/null; then
  alias cat='bat --paging=never --style=plain'
  alias catn='bat --paging=never'  # With line numbers
  alias catf='bat'                  # Full features (paging + numbers + header)
  export BAT_THEME="base16"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"  # Colored man pages
fi

# --- fd (find replacement) ---
if command -v fd &>/dev/null; then
  alias find='fd'
  # Keep original find accessible
  alias gfind='/usr/bin/find'
fi

# --- ripgrep (grep replacement) ---
if command -v rg &>/dev/null; then
  alias grep='rg'
  # Keep original grep accessible
  alias ggrep='/usr/bin/grep'
fi

# --- zoxide (cd replacement) ---
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# --- delta (used via git config, no alias needed) ---
# delta is configured in config/git/delta.gitconfig

# --- Quick helpers ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -p'
alias cls='clear'

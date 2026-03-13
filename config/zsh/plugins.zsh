# Plugin Loading
# Loads zsh plugins installed via Homebrew and fzf-tab from vendor dir.

HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"

# --- Completion system ---
# Add zsh-completions to fpath (must come before compinit)
if [[ -d "$HOMEBREW_PREFIX/share/zsh-completions" ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh-completions" $fpath)
fi

# Initialize completion system (only if not already done)
if ! whence -w compinit | grep -q function; then
  autoload -Uz compinit
  compinit -C  # -C skips security check for faster startup
fi

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # Case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"   # Colored completions
zstyle ':completion:*' menu no                             # Disable default menu (fzf-tab replaces it)
zstyle ':completion:*:descriptions' format '[%d]'          # Group descriptions

# --- fzf-tab (must be loaded after compinit, before other plugins) ---
FZF_TAB_DIR="$MODERN_TERMINAL_DIR/../vendor/fzf-tab"
if [[ -f "$FZF_TAB_DIR/fzf-tab.plugin.zsh" ]]; then
  source "$FZF_TAB_DIR/fzf-tab.plugin.zsh"
  # fzf-tab styling
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null || ls -1 $realpath'
  zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --style=numbers --line-range=:50 $realpath 2>/dev/null || cat $realpath 2>/dev/null || eza -1 --color=always --icons $realpath 2>/dev/null'
  zstyle ':fzf-tab:*' fzf-flags --height=40% --border
fi

# --- Autosuggestions (ghost text from history) ---
if [[ -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#585858"  # Muted ghost text matching theme
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
fi

# --- Syntax Highlighting (MUST be last plugin sourced) ---
if [[ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  # Theme-matched highlighter colors
  ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
  typeset -A ZSH_HIGHLIGHT_STYLES
  ZSH_HIGHLIGHT_STYLES[command]='fg=#a1b56c'           # Green - valid commands
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=#a1b56c'           # Green - builtins
  ZSH_HIGHLIGHT_STYLES[alias]='fg=#a1b56c'             # Green - aliases
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ab4642'     # Red - invalid commands
  ZSH_HIGHLIGHT_STYLES[path]='fg=#7cafc2,underline'    # Blue - file paths
  ZSH_HIGHLIGHT_STYLES[globbing]='fg=#f7ca88'          # Yellow - globs
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#f7ca88'  # Yellow
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#f7ca88'  # Yellow
  ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#f7ca88'  # Yellow
  ZSH_HIGHLIGHT_STYLES[comment]='fg=#585858'           # Dimmed comments
  ZSH_HIGHLIGHT_STYLES[arg0]='fg=#a1b56c'              # Green - first word
fi

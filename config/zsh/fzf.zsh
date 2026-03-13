# fzf Configuration
# Provides fuzzy Ctrl+R history search and Ctrl+T file finder.

HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"

if command -v fzf &>/dev/null; then
  # Theme-matched colors
  export FZF_DEFAULT_OPTS="
    --color=bg+:#282828,bg:#181818,fg:#d8d8d8,fg+:#f8f8f8
    --color=hl:#7cafc2,hl+:#7cafc2,info:#f7ca88,marker:#a1b56c
    --color=prompt:#7cafc2,spinner:#ba8baf,pointer:#ba8baf,header:#86c1b9
    --color=border:#585858,label:#d8d8d8,query:#d8d8d8
    --border=rounded
    --padding=0,1
    --margin=0
    --prompt='❯ '
    --pointer='▶'
    --marker='✓'
    --height=40%
    --layout=reverse
    --info=inline
  "

  # Use fd for file listing if available (respects .gitignore)
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi

  # File preview with bat
  export FZF_CTRL_T_OPTS="
    --preview 'bat --color=always --style=numbers --line-range=:100 {} 2>/dev/null || cat {}'
    --preview-window=right:50%:border-left
    --bind='ctrl-/:toggle-preview'
  "

  # History search preview
  export FZF_CTRL_R_OPTS="
    --preview 'echo {}'
    --preview-window=up:3:wrap
    --bind='ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
    --header='Press CTRL-Y to copy command to clipboard'
  "

  # Directory preview with eza
  export FZF_ALT_C_OPTS="
    --preview 'eza --tree --icons --level=2 --color=always {} 2>/dev/null || ls -la {}'
    --preview-window=right:50%:border-left
  "

  # Load fzf keybindings and completion
  # fzf installed via Homebrew
  if [[ -f "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]]; then
    source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
  fi
  if [[ -f "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" ]]; then
    source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
  fi
fi

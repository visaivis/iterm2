# tmux Aliases & AI Development Layouts

# --- Session aliases ---
# Quick attach/create named dev session
alias tdev='tmux new-session -A -s dev'
alias tkill='tmux kill-session -t'
alias tls='tmux list-sessions'

# iTerm2 control mode (tmux windows become native iTerm2 tabs/panes)
alias tcc='tmux -CC new-session -A -s dev'

# --- AI development workspace ---
# Creates a tmux session with a 2-pane layout:
#   ┌────────────────────────────────┐
#   │                                │
#   │         opencode (80%)         │
#   │                                │
#   ├────────────────────────────────┤
#   │      terminal / shell (20%)    │
#   └────────────────────────────────┘
ai-workspace() {
  local session_name="${1:-ai-dev}"
  local project_dir="${2:-$(pwd)}"

  # If session exists, just attach (and fix layout)
  if tmux has-session -t "$session_name" 2>/dev/null; then
    echo "Attaching to existing session: $session_name"
    ai-layout-fix "$session_name" 2>/dev/null
    tmux attach-session -t "$session_name"
    return
  fi

  echo "Creating AI workspace: $session_name (in $project_dir)"

  # Create session — top pane for opencode
  tmux new-session -d -s "$session_name" -c "$project_dir"

  # Split bottom for terminal (20% height)
  # Note: after split, panes are .1 (top) and .2 (bottom) due to pane-base-index=1
  tmux split-window -v -p 20 -t "$session_name" -c "$project_dir"

  # Explicitly set vertical layout and enforce 80/20 proportions
  tmux select-layout -t "$session_name" main-horizontal
  tmux resize-pane -t "$session_name:.2" -y 20%

  # Start opencode in the top pane (.1)
  if command -v opencode &>/dev/null; then
    tmux send-keys -t "$session_name:.1" 'opencode' C-m
  else
    tmux send-keys -t "$session_name:.1" 'echo "opencode not installed - run: brew install anomalyco/tap/opencode"' C-m
  fi

  # Focus the bottom terminal pane (.2)
  tmux select-pane -t "$session_name:.2"

  # Attach
  tmux attach-session -t "$session_name"
}

# --- Layout fix for existing sessions ---
# Rearranges current session to the standard AI workspace layout:
#   ┌────────────────────────────────┐
#   │         main app (80%)         │
#   ├────────────────────────────────┤
#   │         terminal (20%)         │
#   └────────────────────────────────┘
ai-layout-fix() {
  local session="${1:-$(tmux display-message -p '#S')}"

  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "Session '$session' not found"
    return 1
  fi

  local pane_count
  pane_count=$(tmux list-panes -t "$session" -F '#{pane_index}' | wc -l | tr -d ' ')

  if [[ "$pane_count" -lt 2 ]]; then
    echo "Session has only $pane_count pane(s). Creating split..."
    tmux split-window -v -p 20 -t "$session" -c "#{pane_current_path}"
  fi

  # Apply vertical layout with 80/20 split
  tmux select-layout -t "$session" main-horizontal
  tmux resize-pane -t "$session:.2" -y 20%
  tmux select-pane -t "$session:.2"

  echo "Layout fixed: vertical split (80% top / 20% bottom)"
}

# Alias for quick access
alias tfix='ai-layout-fix'

# --- Custom layouts ---
# Source user overrides if present
if [[ -f "$HOME/.modern-terminal/layouts.zsh" ]]; then
  source "$HOME/.modern-terminal/layouts.zsh"
fi

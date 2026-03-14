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
#   ┌─────────────────────────────────┐
#   │                                 │
#   │         opencode AI TUI         │
#   │            (80%)                │
#   │                                 │
#   ├─────────────────────────────────┤
#   │        terminal (20%)           │
#   └─────────────────────────────────┘
ai-workspace() {
  local session_name="${1:-ai-dev}"
  local project_dir="${2:-$(pwd)}"

  # If session exists, kill it and recreate with the correct layout
  if tmux has-session -t "$session_name" 2>/dev/null; then
    tmux kill-session -t "$session_name"
  fi

  echo "Creating AI workspace: $session_name (in $project_dir)"

  # Create session — top pane runs opencode directly
  if command -v opencode &>/dev/null; then
    tmux new-session -d -s "$session_name" -c "$project_dir" 'opencode'
  else
    tmux new-session -d -s "$session_name" -c "$project_dir"
  fi

  # Split bottom for terminal (20% height)
  tmux split-window -v -p 20 -t "$session_name" -c "$project_dir"

  # Focus the bottom terminal pane
  tmux select-pane -t "$session_name:.1"

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

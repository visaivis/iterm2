# tmux Aliases & AI Development Layouts

# --- Session aliases ---
# Quick attach/create named dev session
alias tdev='tmux new-session -A -s dev'
alias tkill='tmux kill-session -t'
alias tls='tmux list-sessions'

# iTerm2 control mode (tmux windows become native iTerm2 tabs/panes)
alias tcc='tmux -CC new-session -A -s dev'

# --- AI development workspace ---
# Creates a tmux session with a 3-pane layout:
#   ┌──────────────────┬─────────────┐
#   │                  │             │
#   │   coding/git     │  opencode   │
#   │   (70%)          │  AI TUI     │
#   │                  │  (30%)      │
#   ├──────────────────┤             │
#   │  test/logs (25%) │             │
#   └──────────────────┴─────────────┘
ai-workspace() {
  local session_name="${1:-ai-dev}"
  local project_dir="${2:-$(pwd)}"

  # If session exists, just attach
  if tmux has-session -t "$session_name" 2>/dev/null; then
    echo "Attaching to existing session: $session_name"
    tmux attach-session -t "$session_name"
    return
  fi

  echo "Creating AI workspace: $session_name (in $project_dir)"

  # Create session with main coding pane
  tmux new-session -d -s "$session_name" -c "$project_dir"

  # Split right for opencode (30% width)
  tmux split-window -h -p 30 -t "$session_name" -c "$project_dir"

  # Split the left pane bottom for tests/logs (25% height)
  tmux split-window -v -p 25 -t "$session_name:.0" -c "$project_dir"

  # Start opencode in the right pane
  if command -v opencode &>/dev/null; then
    tmux send-keys -t "$session_name:.2" 'opencode' C-m
  else
    tmux send-keys -t "$session_name:.2" 'echo "opencode not installed - run: brew install anomalyco/tap/opencode"' C-m
  fi

  # Label the bottom-left pane
  tmux send-keys -t "$session_name:.1" '# Test runner / log watcher pane' C-m

  # Focus the main coding pane
  tmux select-pane -t "$session_name:.0"

  # Attach
  tmux attach-session -t "$session_name"
}

# --- Custom layouts ---
# Source user overrides if present
if [[ -f "$HOME/.modern-terminal/layouts.zsh" ]]; then
  source "$HOME/.modern-terminal/layouts.zsh"
fi

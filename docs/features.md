# Features

## Color Theme — Dracula

The [Dracula](https://draculatheme.com) color scheme, a popular dark theme known for its readability and vibrant colors.

- **Background**: `#282A36` (dark purple-gray)
- **Foreground**: `#F8F8F2` (warm white)
- **Cursor**: `#F8F8F2` (foreground)
- **Selection**: `#44475A` (current line)
- **Comment**: `#6272A4` (muted blue)
- **Accent colors**: Purple `#BD93F9`, Pink `#FF79C6`, Green `#50FA7B`, Cyan `#8BE9FD`, Red `#FF5555`, Yellow `#F1FA8C`, Orange `#FFB86C`

Installed as a Dynamic Profile — it doesn't replace your existing Default profile. Switch to it in iTerm2 → Settings → Profiles.

## Powerlevel10k

Powerlevel10k is installed automatically via Homebrew. The installer:

- **Auto-sources the theme** via `init.zsh` if not already loaded in your `.zshrc`
- **Preserves your existing `~/.p10k.zsh`** — if you have one, it stays untouched
- **Prompts you to configure** — if no `~/.p10k.zsh` exists, run `p10k configure` after install
- **Applies an overlay** on top of your config with:
  - **Transient prompt**: previous prompts collapse to `❯`, reducing visual noise
  - **Theme-matched colors**: git status, directory, and execution time colors match the dark theme
  - **Command duration**: shows elapsed time for commands taking >3 seconds

Use `--skip-p10k` to disable the overlay and keep your p10k config completely untouched.

## Zsh Plugins

### Syntax Highlighting
Colors your commands as you type:
- **Green** — valid command/alias/builtin
- **Red** — unknown command (typo detection)
- **Blue + underline** — file paths
- **Yellow** — strings and globs

### Autosuggestions
Shows ghost text from your history as you type. Press **→** (right arrow) to accept.

### fzf-tab
Replaces the default Tab completion with a fuzzy picker. Press **Tab** and type to filter.

Previews:
- Files: syntax-highlighted preview via `bat`
- Directories: tree listing via `eza`

## Fuzzy Finder (fzf)

| Keybinding | Action |
|---|---|
| `Ctrl+R` | Fuzzy search command history |
| `Ctrl+T` | Fuzzy find files |
| `Alt+C` | Fuzzy find and cd into directory |
| `Ctrl+Y` (in Ctrl+R) | Copy selected command to clipboard |
| `Ctrl+/` (in Ctrl+T) | Toggle file preview |

Colors and layout are matched to the Dracula theme.

## tmux

### Key Bindings

Prefix is **Ctrl+a** (not the default Ctrl+b).

| Keybinding | Action |
|---|---|
| `Ctrl+a \|` | Split pane vertically |
| `Ctrl+a -` | Split pane horizontally |
| `Ctrl+a h/j/k/l` | Navigate panes (vi-style) |
| `Ctrl+a Ctrl+h/j/k/l` | Resize panes |
| `Ctrl+a c` | New window (in current dir) |
| `Ctrl+a n/p` | Next/previous window |
| `Ctrl+a r` | Reload config |
| `Ctrl+a I` | Install TPM plugins |
| `Ctrl+a Ctrl+s` | Save session (resurrect) |
| `Ctrl+a Ctrl+r` | Restore session (resurrect) |

### Copy Mode
Enter copy mode with `Ctrl+a [`, then use vi keys:
- `v` to start selection
- `y` to copy to system clipboard
- Mouse drag also copies to clipboard

### iTerm2 Integration
Use `tmux -CC` (or the `tcc` alias) for native integration — tmux windows become real iTerm2 tabs.

### AI Workspace

Run `ai-workspace` to create a 3-pane tmux session:

```
┌──────────────────┬─────────────┐
│                  │             │
│   coding/git     │  opencode   │
│   (main pane)    │  AI TUI     │
│                  │             │
├──────────────────┤             │
│  test/logs       │             │
└──────────────────┴─────────────┘
```

Usage:
```sh
ai-workspace              # Default session name: ai-dev
ai-workspace myproject    # Custom session name
ai-workspace proj /path   # Custom name + directory
```

## Modern CLI Replacements

| Original | Replacement | Key Aliases |
|---|---|---|
| `ls` | `eza` | `ls`, `ll` (long), `la` (all), `tree` |
| `cat` | `bat` | `cat` (plain), `catn` (numbered), `catf` (full) |
| `find` | `fd` | `find` (original: `gfind`) |
| `grep` | `ripgrep` | `grep` (original: `ggrep`) |
| `cd` | `zoxide` | `cd` (learns frequent directories) |
| `git diff` | `delta` | Automatic via gitconfig |

Original commands remain accessible:
- `/bin/ls`, `/usr/bin/find`, `/usr/bin/grep`
- Or via aliases: `gfind`, `ggrep`

## OpenCode AI CLI

Interactive TUI for AI-assisted coding:
```sh
opencode              # Launch interactive TUI
opencode -p "..."     # One-shot prompt
opencode init         # Initialize for current project (creates AGENTS.md)
```

Inside the TUI:
- **Tab** — switch between Build (full access) and Plan (read-only) modes
- **/models** — switch AI model
- **/share** — share conversation link

## Customization

### Override aliases
Create `~/.modern-terminal/custom.zsh` (not tracked by the repo) for personal overrides.

### Custom tmux layouts
Create `~/.modern-terminal/layouts.zsh` to define additional workspace layouts.

### Skip features
Re-run install with skip flags:
```sh
./install.sh --skip-aliases    # Keep your own ls/cat/etc.
./install.sh --skip-plugins    # Keep your own zsh plugins
./install.sh --skip-tmux       # Keep your own tmux config
```

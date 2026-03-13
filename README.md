# Modern Terminal Configuration

[![CI](https://github.com/visaivis/iterm2/actions/workflows/ci.yml/badge.svg)](https://github.com/visaivis/iterm2/actions/workflows/ci.yml)
[![Integration Tests](https://github.com/visaivis/iterm2/actions/workflows/integration.yml/badge.svg)](https://github.com/visaivis/iterm2/actions/workflows/integration.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-supported-brightgreen?logo=apple)](https://github.com/visaivis/iterm2)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-brightgreen?logo=gnu-bash)](https://www.shellcheck.net/)
[![GitHub Release](https://img.shields.io/github/v/release/visaivis/iterm2?include_prereleases)](https://github.com/visaivis/iterm2/releases)
[![GitHub Stars](https://img.shields.io/github/stars/visaivis/iterm2?style=social)](https://github.com/visaivis/iterm2)

A reproducible, one-command setup for a polished iTerm2 + zsh development environment on macOS — with AI-assisted coding via [OpenCode](https://opencode.ai).

**Safe by design**: every file is backed up before being touched, and `uninstall.sh` fully reverses everything.

## What You Get

- **Dark theme** — curated color scheme across iTerm2, tmux, fzf, and git diffs
- **Syntax highlighting** — commands colored as you type (green = valid, red = typo)
- **Autosuggestions** — ghost-text completions from shell history
- **Fuzzy everything** — Ctrl+R history search, Tab completion with previews, file finder
- **tmux with AI layout** — persistent sessions, `ai-workspace` opens coding + OpenCode + test panes
- **Modern CLI tools** — `eza`, `bat`, `fd`, `ripgrep`, `zoxide`, `delta` aliased over defaults
- **Powerlevel10k** — auto-installed, with transient prompt, theme-matched colors, command duration
- **OpenCode CLI** — AI coding assistant in your terminal

## Prerequisites

- **macOS** (Apple Silicon or Intel)
- **[Homebrew](https://brew.sh)** — `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- **[iTerm2](https://iterm2.com)** — `brew install --cask iterm2`
- **zsh** (default on macOS)

## Quick Start

```sh
# 1. Clone this repo
git clone <repo-url> ~/personal/iterm2
cd ~/personal/iterm2

# 2. Preview what will change (recommended)
./install.sh --dry-run

# 3. Install
./install.sh

# 4. Restart your terminal
#    (if no p10k config exists, run: p10k configure)

# 5. In iTerm2:
#    Settings → Profiles → select "Modern Dark" → set as Default

# 6. Install tmux plugins (inside tmux)
#    Press: Ctrl+a I

# 7. Try the AI workspace
ai-workspace
```

## What the Installer Does

| Step | What | Reversible? |
|---|---|---|
| Brew packages | Installs tools + Powerlevel10k from `Brewfile` | `--remove-packages` on uninstall |
| iTerm2 profile | Adds "Modern Dark" Dynamic Profile | Removed on uninstall |
| Zsh config | Symlinks `~/.modern-terminal/` + appends 1 line to `.zshrc` | Line removed, symlink deleted |
| tmux config | Symlinks `~/.tmux.conf` + installs TPM | Symlink removed, original restored |
| Git config | Adds `[include]` for delta | Include removed |
| Powerlevel10k | Verifies install, preserves existing `~/.p10k.zsh` | Theme stays installed; overlay removed with config |

Every modified file is backed up to `~/.terminal-config-backup/<timestamp>/`.

## Conflict Detection

The installer scans your existing configuration before making changes:

```
⚠ Conflict Report
─────────────────────────────────────────────────────
  CONFLICT                  FILE:LINE       ACTION
─────────────────────────────────────────────────────
  duplicate compinit        .zshrc:54       safe: skips if loaded
  alias ls already defined  .zshrc:12       skip or remove
  existing ~/.tmux.conf     ~/.tmux.conf    backup + replace
─────────────────────────────────────────────────────
```

- **safe:** — handled automatically
- **skip or remove** — you choose: use `--skip-aliases` or edit your `.zshrc`
- **manual:** — must be fixed before install can proceed

## Testing in a Sandbox

Preview the full setup **without modifying your shell** using the sandboxed test script:

```sh
# Install just the brew tools (safe — only adds packages to /opt/homebrew)
./test.sh --install-deps

# Launch a sandboxed zsh with the full config
./test.sh

# Also preview the iTerm2 color theme
./test.sh --profile

# Test tmux + ai-workspace layout
./test.sh --with-tmux
```

Type `exit` to return to your normal shell. The sandbox is deleted automatically.

**How it works**: zsh's `ZDOTDIR` variable redirects config loading to a temp directory that sources our config instead of your `~/.zshrc`. Nothing is written to your home directory.

| Component | Isolated? | Details |
|---|---|---|
| `~/.zshrc` | ✅ Fully | ZDOTDIR redirects to temp dir |
| Aliases, plugins, fzf | ✅ Fully | Loaded from repo, not ~/.zshrc |
| tmux config | ✅ Fully | Uses `-f` flag, no symlink created |
| iTerm2 profile | ⚠️ Additive | Adds "Modern Dark" option, doesn't replace Default. Remove: `rm ~/Library/Application\ Support/iTerm2/DynamicProfiles/modern-dark.json` |
| Brew packages | ⚠️ System-wide | Installs to /opt/homebrew — tools are inert until aliased |
| p10k config | 🔗 Read-only | Uses your existing `~/.p10k.zsh` so the prompt renders correctly |

## Uninstall

```sh
# Preview what will be restored
./uninstall.sh --dry-run

# Restore everything
./uninstall.sh

# Also remove brew packages
./uninstall.sh --remove-packages

# Use a specific backup
./uninstall.sh --backup-id 20240101_120000
```

## Customization

### Skip specific features
```sh
./install.sh --skip-brew       # Already have the tools
./install.sh --skip-aliases    # Keep your own ls/cat/grep aliases
./install.sh --skip-tmux       # Keep your own tmux config
./install.sh --skip-plugins    # Keep your own zsh plugin setup
./install.sh --skip-iterm      # Skip iTerm2 profile
./install.sh --skip-p10k       # Skip p10k overlay
./install.sh --skip-git        # Skip delta config
```

### Personal overrides
- **Custom aliases/functions**: create `~/.modern-terminal/layouts.zsh`
- **tmux layout tweaks**: edit `config/tmux/tmux.conf` in this repo

## Project Structure

```
├── README.md                      ← You are here
├── docs/
│   ├── architecture.md            ← Mermaid flow diagrams
│   └── features.md                ← Feature details + keybindings
├── install.sh                     ← Safe installer
├── uninstall.sh                   ← Full reversal
├── Brewfile                       ← Homebrew dependencies
├── config/
│   ├── zsh/                       ← Modular zsh config
│   │   ├── init.zsh              ← Entry point
│   │   ├── plugins.zsh           ← Plugin loading order
│   │   ├── aliases.zsh           ← Modern CLI aliases
│   │   ├── fzf.zsh              ← Fuzzy finder config
│   │   ├── p10k-overlay.zsh     ← Prompt enhancements
│   │   ├── tmux.zsh             ← tmux + ai-workspace
│   │   └── iterm2-integration.zsh
│   ├── iterm2/
│   │   └── modern-dark.json      ← Dynamic Profile
│   ├── tmux/
│   │   └── tmux.conf             ← tmux configuration
│   └── git/
│       └── delta.gitconfig        ← Diff config
└── vendor/
    └── fzf-tab/                   ← Cloned at install time
```

## Documentation

- [Architecture](docs/architecture.md) — install/uninstall flows, zsh sourcing chain, diagrams
- [Features](docs/features.md) — keybindings, customization, detailed feature docs

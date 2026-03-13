# AI Agent Context

This file provides context for AI coding agents working on this repository.

## Project Purpose

A reproducible, one-command setup for a modern iTerm2 + zsh terminal environment on macOS. Installs curated CLI tools via Homebrew, configures zsh with modular plugins, sets up tmux with a developer-friendly layout, and optionally integrates OpenCode CLI for AI-assisted development.

## Architecture

```
├── install.sh          # Main installer (supports --dry-run, --skip-* flags)
├── uninstall.sh        # Manifest-based reversal of install
├── test.sh             # ZDOTDIR sandbox for isolated testing
├── Brewfile            # Homebrew dependencies
├── config/
│   ├── iterm2/         # iTerm2 Dynamic Profile (JSON)
│   ├── zsh/            # Modular zsh configs (init, plugins, aliases, fzf, tmux, p10k-overlay)
│   ├── tmux/           # tmux.conf with TPM plugin manager
│   └── git/            # Delta diff configuration
└── docs/               # Architecture diagrams, feature docs
```

## Conventions

- **Language**: All config scripts are POSIX-compatible bash or zsh. No compiled languages.
- **Linting**: Shell scripts must pass ShellCheck. Zsh files must pass `zsh -n`.
- **JSON**: iTerm2 profile must be valid JSON (`python3 -m json.tool`).
- **Backups**: The installer creates timestamped backups and a manifest file at `~/.modern-terminal-backup/`. The uninstaller reads this manifest to reverse changes.
- **Conflict detection**: `install.sh` warns if existing `.zshrc` has competing config (duplicate PATH entries, conflicting plugins).
- **Modularity**: Each zsh feature is a separate file in `config/zsh/`. Add new features by creating a new `.zsh` file and sourcing it from `init.zsh`.

## Testing

```bash
# Isolated sandbox (no system changes)
bash test.sh

# Sandbox with dependency install
bash test.sh --install-deps

# Dry-run install (preview only)
bash install.sh --dry-run
```

## Common Tasks

- **Add a CLI tool**: Add to `Brewfile`, create alias in `config/zsh/aliases.zsh`, document in `docs/features.md`
- **Modify theme colors**: Edit `config/iterm2/modern-dark.json` (ANSI color values are in the `Profiles[0]` object)
- **Add tmux keybinding**: Edit `config/tmux/tmux.conf`
- **Add zsh plugin**: Add to `config/zsh/plugins.zsh`, update `Brewfile` if it's a Homebrew plugin

## CI Workflows

- `ci.yml` — ShellCheck, zsh syntax, JSON validation, markdown lint (runs on every push/PR)
- `integration.yml` — Dry-run install/uninstall + sandbox test on macOS (runs when scripts/config change)
- `brew-audit.yml` — Weekly check for outdated Homebrew packages
- `auto-release.yml` — Determines semver bump from PR title on merge, updates CHANGELOG, creates tag
- `release.yml` — Auto-creates GitHub Release on tag push (triggered by `auto-release.yml`)
- `issue-triage.yml` — Auto-labels new issues with `triage` and detects type from template

## Agentic SDLC

This project is agentic-first. Issues flow through a label-based lifecycle managed by AI agents:

```
triage → approved → in-progress → pr-submitted → (closed)
```

**Before working on any issue**, read the SDLC skill:
- `.github/skills/sdlc-agent.md` — Full issue-to-PR workflow (branch naming, commit conventions, validation gates, PR standards)
- `.github/ISSUE_LIFECYCLE.md` — Label definitions and state transitions

Key rules:
- **NEVER approve your own issues** — moving an issue from `triage` to `approved` is exclusively a human action. The agent must not apply the `approved` label under any circumstance.
- **NEVER merge your own PRs** — merging is exclusively a human action. The agent must not merge, auto-merge, or request auto-merge on any PR it created.
- **NEVER approve your own PRs** — the agent must not submit approving reviews on its own PRs.
- Only work on issues labeled `approved` (the human Overseer gate)
- Branch pattern: `agent/<issue-number>-<short-slug>`
- Validate locally before pushing (ShellCheck, zsh -n, JSON, dry-run install)
- PRs must link the issue with `Closes #N` and include co-author attribution

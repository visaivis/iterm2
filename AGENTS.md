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
├── scripts/
│   └── bedrock-auth.sh  # AWS SSO auth helper (installed to ~/bin/bedrock-auth)
├── config/
│   ├── iterm2/         # iTerm2 Dynamic Profile (JSON)
│   ├── zsh/            # Modular zsh configs (init, plugins, aliases, fzf, tmux, aws, p10k-overlay)
│   ├── opencode/       # OpenCode config (amazon-bedrock provider, Claude Sonnet 4.5 default)
│   ├── tmux/           # tmux.conf with TPM plugin manager
│   └── git/            # Delta diff configuration
└── docs/               # Architecture diagrams, feature docs, aws-bedrock-setup
```

## Conventions

- **Language**: All config scripts are POSIX-compatible bash or zsh. No compiled languages.
- **Linting**: Shell scripts must pass ShellCheck. Zsh files must pass `zsh -n`.
- **JSON**: iTerm2 profile must be valid JSON (`python3 -m json.tool`).
- **Backups**: The installer creates timestamped backups and a manifest file at `~/.modern-terminal-backup/`. The uninstaller reads this manifest to reverse changes.
- **Conflict detection**: `install.sh` warns if existing `.zshrc` has competing config (duplicate PATH entries, conflicting plugins).
- **Modularity**: Each zsh feature is a separate file in `config/zsh/`. Add new features by creating a new `.zsh` file and sourcing it from `init.zsh`.

## Security Conventions

- **`~/.aws/` directory**: Always created with `mkdir -p ~/.aws && chmod 700 ~/.aws` to prevent other users from reading SSO tokens or config.
- **`~/.aws/config`**: Set `chmod 600 ~/.aws/config` immediately after any append or write. The file contains SSO profile details and must not be world-readable.
- **`~/.aws/active_profile`**: Set `chmod 600` after writing. Used by `aws.zsh` to persist the selected profile across shells.
- **Backup directory**: Created with `mkdir -m 700 -p` since it may contain copies of sensitive AWS config files.
- **SSO access token**: Short-lived (8 hours), passed via environment variable to Python subprocesses — never written to disk or logged.
- **Remote fetches**: `curl` downloads and `git clone --depth 1` do not verify checksums. Acceptable for developer tooling over HTTPS, but be aware of the supply-chain trust model.

## Testing

```bash
# Isolated sandbox (no system changes)
bash test.sh

# Sandbox with dependency install
bash test.sh --install-deps

# Dry-run install (preview only)
bash install.sh --dry-run
```

## AWS Bedrock Provider

OpenCode is pre-configured to use `amazon-bedrock` as its LLM provider. The installer:
- Copies `scripts/bedrock-auth.sh` to `~/bin/bedrock-auth` (executable)
- Bootstraps `~/.aws/config` with the `WFS-Architects-RD` SSO profile (idempotent, appends only if missing)
- Copies `config/opencode/opencode.json` to `~/.config/opencode/opencode.json`
- Sources `config/zsh/aws.zsh` which sets `AWS_PROFILE`, `AWS_REGION`, and `bedrock-login/logout/status` aliases

AWS account: `711387094947` | Role: `WFSPowerUserAccess` | SSO session: `my-sso` | Region: `us-east-1`

## Common Tasks

- **Add a CLI tool**: Add to `Brewfile`, create alias in `config/zsh/aliases.zsh`, document in `docs/features.md`
- **Modify theme colors**: Edit `config/iterm2/dracula.json` (ANSI color values are in the `Profiles[0]` object)
- **Add tmux keybinding**: Edit `config/tmux/tmux.conf`
- **Add zsh plugin**: Add to `config/zsh/plugins.zsh`, update `Brewfile` if it's a Homebrew plugin
- **Change default AI model**: Edit `config/opencode/opencode.json` (`model` field); see `docs/aws-bedrock-setup.md` for Bedrock IDs
- **Update Bedrock auth script**: Edit `scripts/bedrock-auth.sh`; re-run `./install.sh` to redeploy to `~/bin/bedrock-auth`

## CI Workflows

- `ci.yml` — ShellCheck, zsh syntax, JSON validation, markdown lint (runs on every push/PR)
- `integration.yml` — Dry-run install/uninstall + sandbox test on macOS (runs when scripts/config change)
- `brew-audit.yml` — Weekly check for outdated Homebrew packages
- `auto-release.yml` — Determines semver bump from PR title on merge, updates CHANGELOG, creates tag
- `release.yml` — Auto-creates GitHub Release on tag push (triggered by `auto-release.yml`)
- `issue-triage.yml` — Auto-labels new issues with `triage` and detects type from template
- `pr-gate.yml` — Validates PR has a linked, approved issue (required status check, blocks merge)
- `opencode.yml` — Runs OpenCode cloud agent on `/opencode` or `/oc` comments (issues and PRs)

## Agent Secret Management

Agents access secrets through two modes depending on where they run. See `docs/agent-secrets.md` for the full setup guide.

**Local agents** (opencode TUI, Warp):
- 1Password desktop app + `op run` with `op://` references
- Touch ID / biometric gates every agent launch — no tokens stored on disk
- Each project has its own 1Password vault — agents cannot access secrets from other projects
- The `.env.agent` file contains `op://` references (not secrets) and is safe to commit
- Launch: `op run --env-file=.env.agent -- opencode`

**Cloud agents** (OpenCode GitHub):
- Triggered by `/opencode` or `/oc` comments on issues and PRs
- Runs on GitHub Actions runners with secrets injected via `${{ secrets.* }}`
- OpenCode GitHub App provides installation tokens for repo operations
- Runner is destroyed after workflow completes — no secrets persist

## Agentic SDLC

This project is agentic-first. Issues flow through a label-based lifecycle managed by AI agents:

```
triage → approved → in-progress → pr-submitted → (closed)
```

**Before working on any issue**, read the SDLC skills:
- `.agents/skills/sdlc-agent/SKILL.md` — Full issue-to-PR workflow (branch naming, commit conventions, validation gates, PR standards)
- `.agents/skills/issue-lifecycle/SKILL.md` — Label definitions and state transitions

Key rules:
- **NEVER approve your own issues** — moving an issue from `triage` to `approved` is exclusively a human action. The agent must not apply the `approved` label under any circumstance.
- **NEVER merge your own PRs** — merging is exclusively a human action. The agent must not merge, auto-merge, or request auto-merge on any PR it created.
- **NEVER approve your own PRs** — the agent must not submit approving reviews on its own PRs.
- Only work on issues labeled `approved` (the human Overseer gate)
- Branch pattern: `agent/<issue-number>-<short-slug>`
- Validate locally before pushing (ShellCheck, zsh -n, JSON, dry-run install)
- PRs must link the issue with `Closes #N` and include co-author attribution

### Enforcement

Issue linkage and approval are enforced at three layers:

1. **Server-side** (`pr-gate.yml`) — Required status check that blocks merge if the PR doesn't link an approved issue. This is the real gate and cannot be bypassed.
2. **Client-side** (git hooks) — `commit-msg` rejects commits without issue references; `pre-push` validates branch naming. These catch mistakes early but can be skipped with `--no-verify`.
3. **SDLC skill** — Agents are instructed to always create issues before PRs and follow the full lifecycle.

To install git hooks after cloning:
```bash
bash .github/hooks/install.sh
```

## Build, Lint, and Test Commands

Run these locally before pushing (all run automatically in CI):

```bash
# ShellCheck - lint bash scripts (excludes config/zsh)
shellcheck install.sh uninstall.sh test.sh

# Zsh syntax check
for f in config/zsh/*.zsh; do zsh -n "$f"; done

# JSON validation
python3 -m json.tool config/iterm2/dracula.json > /dev/null

# Markdown lint
markdownlint "**/*.md"

# tmux config validation
tmux -f config/tmux/tmux.conf start-server \; kill-server

# Full sandbox test
bash test.sh

# Dry-run install
bash install.sh --dry-run
```

## Code Style Guidelines

### Bash/Zsh Scripts
- **Shebang**: `#!/usr/bin/env bash` or `#!/bin/zsh`
- **Error handling**: Always use `set -euo pipefail` at script top
- **Variables**: Use `local` for function-scoped vars; uppercase for constants
- **Functions**: Use `verb_noun()` naming (e.g., `backup_file`)
- **Colors**: Define at top: `RED='\033[0;31m'`, `GREEN='\033[0;32m'`, etc.
- **Logging**: Use helpers: `info()`, `ok()`, `warn()`, `err()`, `header()`
- **Quotes**: Always quote variables: `"$file"` not `$file`
- **Conditionals**: Use `[[ ]]` in zsh/bash

### Zsh Config Files
- **Sourcing**: Use `${0:A:h}` to get script directory
- **Module order**: Document in comments (see `init.zsh`)
- **Conditional loads**: Check file existence before sourcing

### JSON Configuration
- Validate with `python3 -m json.tool`
- Use 2-space indentation

### Git Commits
- Format: `<type>(<scope>): <subject>` — e.g., `feat(zsh): add aws plugin`
- Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`
- Include issue reference: `Closes #123`

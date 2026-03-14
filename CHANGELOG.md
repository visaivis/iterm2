# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `pre-commit` git hook that blocks direct commits on `main`, enforcing the branch-and-PR workflow (#15)
  - Exceptions: merge commits, automated release commits (`github-actions[bot]`), and `--no-verify`

## [1.9.4] - 2026-03-14

### Fixed

- Resolve iTerm2 escape sequence leakage (`1016;4$y...`) in `ai-workspace` by disabling unused tmux passthrough (#43)
- Increase tmux `escape-time` from 0 to 10ms to prevent misparsing of multi-byte escape sequences (#43)

### Changed

- `ai-workspace` now prompts for confirmation before killing an existing session (#43)
- `ai-workspace` refuses to run inside tmux (prevents nested sessions); suggests `ai-layout-fix` instead (#43)
- `ai-layout-fix` gives a clear error when called outside tmux without a session name (#43)

### Removed

- Dead `terminal-features` overrides with invalid syntax in `tmux.conf` (#43)
- Redundant `terminal-overrides` entry for `xterm-256color` (already matched by `*256col*` glob) (#43)
- Dead copy-mode `y` and `MouseDragEnd1Pane` bindings (handled by `tmux-yank` plugin) (#43)
- `sleep` and `clear` timing hacks from `ai-workspace` (no longer needed with passthrough disabled) (#43)

### Docs

- Update `docs/features.md` AI Workspace section to show actual 2-pane layout (was stale 3-pane) (#43)
- Update `docs/architecture.md` mermaid diagram to match 2-pane layout (#43)

## [1.3.0] - 2026-03-14

### Changed

- Replace custom "Modern Dark" iTerm2 color scheme with the official [Dracula](https://draculatheme.com) theme (#16)
- Rename iTerm2 Dynamic Profile from `modern-dark.json` to `dracula.json`
- Profile name changed from "Modern Dark" to "Dracula" in installer, uninstaller, and sandbox test

## [1.2.2] - 2026-03-14

### Fixed

- Replace defunct `anomalyco/tap/opencode` with official Homebrew core formula `opencode` in Brewfile (#13)

## [1.2.1] - 2026-03-14

### Fixed

- Remove deprecated `--no-lock` flag from `brew bundle` commands in `install.sh`, `test.sh`, and `brew-audit.yml` (#11)

## [1.2.0] - 2026-03-13

### Added

- `pr-gate.yml` workflow — required status check that validates PRs link an approved issue before merge
- Git hooks (`commit-msg`, `pre-push`) for local validation of issue references and branch naming
- Hook install script: `bash .github/hooks/install.sh`
- Agent secret management guide (`docs/agent-secrets.md`) — dual-mode architecture for local (1Password desktop app + `op run`) and cloud (OpenCode GitHub) agent secret access
- `opencode.yml` workflow for cloud agent triggered by `/opencode` comments on issues and PRs
- `.env.agent` environment reference file with `op://` references for local agent secret injection
- `auto-release.yml` workflow for automated releases on PR merge
- `RELEASE_TOKEN` GitHub Actions secret for release workflow authentication

### Changed

- Simplified local agent secret management — replaced service account + macOS Keychain with 1Password desktop app integration (Touch ID / biometric)

## [1.1.0] - 2026-03-13

### Added

- Explicit agent governance rules: agents must never self-approve issues, merge own PRs, or approve own PRs
- Powerlevel10k is now installed automatically via Brewfile (no longer a manual prerequisite)
- `init.zsh` auto-sources the p10k theme if not already loaded by the user's `.zshrc`
- `install.sh` step 6: verifies p10k install, detects existing `~/.p10k.zsh`, preserves user config
- Uninstall summary notes that p10k remains installed and `~/.p10k.zsh` is untouched
- PR template and SDLC skill now require documentation updates with every PR

### Changed

- Removed Powerlevel10k from Prerequisites in README (auto-installed now)
- Install summary dynamically shows "run p10k configure" step when no config exists

## [1.0.0] - 2026-03-13

### Added

- One-command installer (`install.sh`) with `--dry-run`, `--skip-brew`, `--skip-zsh`, `--skip-tmux`, `--skip-iterm`, `--skip-git` flags
- Manifest-based uninstaller (`uninstall.sh`) with `--remove-packages` option
- Isolated sandbox testing via `test.sh` using ZDOTDIR
- Curated Homebrew dependencies: tmux, fzf, eza, bat, fd, ripgrep, zoxide, git-delta, opencode
- Modular zsh configuration: plugins, aliases, fzf integration, tmux auto-attach, p10k overlay, iTerm2 shell integration
- iTerm2 Dynamic Profile with modern dark theme and MesloLGS Nerd Font
- tmux configuration with true color, mouse support, vi copy mode, TPM
- Git delta side-by-side diff configuration
- Conflict detection for existing zsh configuration
- Architecture and feature documentation
- CI workflows: ShellCheck, zsh syntax, JSON validation, markdown lint, integration tests
- Weekly Homebrew dependency audit workflow
- Automated release workflow on tag push
- Renovate configuration for GitHub Actions dependency management
- Community files: LICENSE (MIT), CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, issue/PR templates

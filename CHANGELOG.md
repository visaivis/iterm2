# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

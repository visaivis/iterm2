# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Explicit agent governance rules: agents must never self-approve issues, merge own PRs, or approve own PRs

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

# Contributing

Thanks for your interest in contributing! Here's how to get started.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/<your-user>/iterm2.git`
3. Create a branch: `git checkout -b feat/your-feature`
4. Test in the sandbox: `bash test.sh --install-deps`

## Development Workflow

- **Shell scripts** must pass [ShellCheck](https://www.shellcheck.net/)
- **Zsh configs** must pass `zsh -n` syntax checks
- **JSON files** must be valid (use `python3 -m json.tool`)
- Run `bash test.sh` to validate changes in an isolated sandbox before submitting

## Pull Request Process

1. Ensure all CI checks pass
2. Update documentation if you change behavior
3. Add a changelog entry under `## [Unreleased]` in `CHANGELOG.md`
4. Use descriptive commit messages (`feat:`, `fix:`, `docs:`, `chore:`)

## What to Contribute

- New CLI tool integrations (add to `Brewfile` + alias in `config/zsh/aliases.zsh`)
- Theme improvements (`config/iterm2/dracula.json`)
- Tmux layout presets
- Documentation improvements
- Bug fixes in install/uninstall scripts

## Reporting Issues

Use the issue templates for bug reports and feature requests. Include your macOS version, shell version, and any relevant config details.

## Agentic Workflow

This project uses an AI-agent-driven development lifecycle. Here's how it works:

1. **You submit an issue** using the bug report or feature request template
2. **A maintainer triages it** — adds priority/type labels and marks it `approved` when ready
3. **An AI agent picks it up** — creates a branch, implements the change, validates it, and submits a PR
4. **The maintainer reviews and merges** — standard code review, just like any other PR

You can still contribute manually! Human PRs are welcome and follow the same process described above. The AI agent workflow is documented in detail in [`.github/ISSUE_LIFECYCLE.md`](.github/ISSUE_LIFECYCLE.md).

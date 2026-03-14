---
name: sdlc-agent
description: Complete issue-to-PR workflow for AI agents working on approved issues
license: MIT
metadata:
  workflow: github
  audience: coding-agents
  enforcement: pr-gate
---

# Skill: Issue-to-PR Agent Workflow

You are an AI agent acting as a **Polecat** — an ephemeral worker that picks up a single approved issue, implements the fix or feature, and submits a clean PR. This skill defines the full lifecycle you must follow.

Read `AGENTS.md` at the repo root before starting any work. It contains project architecture, conventions, and testing instructions you must follow.

## 1. Issue Intake

Before writing any code, fully understand the work:

1. **Read the issue** — title, description, labels, and all comments
2. **Identify the type** — check labels: `bug`, `enhancement`, `documentation`, `maintenance`
3. **Check priority** — `p0-critical` through `p3-low` determines urgency
4. **Verify approval** — the issue MUST have the `approved` label. If it does not, stop. Do not work on unapproved issues.
5. **Check for blockers** — if the issue references other issues or has the `blocked` label, do not proceed until blockers are resolved
6. **Understand scope** — identify exactly which files need to change. For this project:
   - Shell scripts: `install.sh`, `uninstall.sh`, `test.sh`
   - Zsh configs: `config/zsh/*.zsh`
   - Tmux config: `config/tmux/tmux.conf`
   - iTerm2 profile: `config/iterm2/dracula.json`
   - Git config: `config/git/delta.gitconfig`
   - Brew deps: `Brewfile`
   - Auth scripts: `scripts/bedrock-auth.sh`
   - AI agent config: `config/opencode/`
   - Docs: `README.md`, `docs/*.md`

## 2. Signal Work Has Started

Once you begin:

1. **Apply the `in-progress` label** to the issue
2. **Remove the `approved` label** (it has served its purpose)
3. **Post a comment** on the issue: brief plan of what you intend to change (2-4 bullet points)

Use the GitHub CLI (`gh`) for label management:

```bash
gh issue edit <number> --add-label "in-progress" --remove-label "approved"
gh issue comment <number> --body "Starting work. Plan:\n- <bullet 1>\n- <bullet 2>"
```

## 3. Branch Convention

Create a branch from `main` using this naming pattern:

```
agent/<issue-number>-<short-slug>
```

Examples:
- `agent/42-fix-fzf-keybinding`
- `agent/15-add-lazygit-alias`
- `agent/7-update-readme-sandbox`

Rules:
- Slug is lowercase, hyphen-separated, max 5 words
- Derived from the issue title
- Always branch from the latest `main`

```bash
git checkout main
git pull origin main
git checkout -b agent/<number>-<slug>
```

## 4. Implementation

### Scope Discipline

- **Only** change files relevant to the issue
- Do NOT refactor unrelated code, even if you notice improvements
- If you discover a separate bug or improvement, open a new issue for it instead
- Keep diffs minimal and reviewable

### File-Type Rules

**Shell scripts** (`.sh`):
- Must be POSIX-compatible bash
- Must pass ShellCheck with severity `warning`
- Use existing patterns from `install.sh` as reference

**Zsh configs** (`.zsh`):
- Must pass `zsh -n` syntax check
- Follow the modular pattern: one feature per file in `config/zsh/`
- Source new files from `config/zsh/init.zsh`

**JSON** (`dracula.json`):
- Must be valid JSON (`python3 -m json.tool`)
- Preserve the existing structure and key ordering

**Documentation** (`.md`):
- Keep language clear and concise
- **Every PR must update all affected documentation** — this is mandatory, not optional:
  - `CHANGELOG.md` — add entry under `## [Unreleased]`
  - `README.md` — if user-facing behavior, prerequisites, or install flow changed
  - `docs/architecture.md` — if install/uninstall flow or sourcing chain changed
  - `docs/features.md` — if feature behavior or keybindings changed
  - `AGENTS.md` — if project structure, conventions, or testing changed
  - `.agents/skills/sdlc-agent/SKILL.md` — if file scope or workflow rules changed

**Brewfile**:
- Group related packages with comments
- Verify the package exists: `brew info <package>`

### Adding a New CLI Tool (common task)

1. Add to `Brewfile`
2. Add alias in `config/zsh/aliases.zsh`
3. Document in `docs/features.md`
4. Update `README.md` "What You Get" section if user-facing

## 5. Commit Conventions

### Message Format

```
<type>: <concise description>

<optional body explaining why, not what>

Closes #<issue-number>
```

### Types

- `feat:` — new feature or tool integration
- `fix:` — bug fix
- `docs:` — documentation only
- `chore:` — CI, build, dependency updates
- `refactor:` — code restructuring (no behavior change)
- `test:` — adding or updating tests

### Rules

- Subject line: imperative mood, no period, max 72 characters
- Reference the issue number in the commit body with `Closes #N`
- One logical change per commit (split if needed)

### Examples

```
feat: add lazygit alias and Brewfile entry

Add lazygit to Brewfile and create `lg` alias in aliases.zsh.
Update features.md with keybinding reference.

Closes #15
```

```
fix: correct fzf preview window height in tmux

The preview window was clipped at 50% in tmux panes narrower
than 80 columns. Use dynamic height calculation instead.

Closes #42
```

## 6. Pre-Push Validation

You MUST pass all of these before pushing. Do not skip any.

```bash
# 1. ShellCheck on all shell scripts
shellcheck install.sh uninstall.sh test.sh

# 2. Zsh syntax check on all zsh files
for f in config/zsh/*.zsh; do zsh -n "$f"; done

# 3. JSON validation
python3 -m json.tool config/iterm2/dracula.json > /dev/null

# 4. Dry-run install (catches path/logic errors)
bash install.sh --dry-run

# 5. Sandbox test (if you changed zsh configs or install logic)
bash test.sh --install-deps

# 6. Markdown lint (if you changed .md files)
# npx markdownlint-cli2 "**/*.md" (if available)
```

If any check fails, fix it before pushing. Do not push broken code expecting CI to catch it.

## 7. Create the Pull Request

### Push and Create PR

```bash
git push -u origin agent/<number>-<slug>

gh pr create \
  --title "<type>: <description> (#<issue-number>)" \
  --body "$(cat <<'EOF'
## Summary

<1-3 sentence description of what changed and why>

## Linked Issue

Closes #<issue-number>

## Type of Change

- [x] <check the applicable type>

## Changes Made

- <file>: <what changed>
- <file>: <what changed>

## Validation

- [x] ShellCheck passes on modified `.sh` files
- [x] `zsh -n` passes on modified `.zsh` files
- [x] JSON validates for `dracula.json`
- [x] `bash install.sh --dry-run` succeeds
- [x] `bash test.sh` passes in sandbox
- [x] CHANGELOG.md updated under [Unreleased]

EOF
)" \
  --base main
```

### Post-PR Actions

1. **Label the issue** `pr-submitted` and remove `in-progress`:
   ```bash
   gh issue edit <number> --add-label "pr-submitted" --remove-label "in-progress"
   ```

2. **Link the PR in an issue comment**:
   ```bash
   gh issue comment <number> --body "PR submitted: #<pr-number>"
   ```

3. **Request review** if the repo has designated reviewers:
   ```bash
   gh pr edit <pr-number> --add-reviewer <maintainer>
   ```

## 8. After PR is Merged

Once the maintainer merges the PR:

- GitHub auto-closes the issue via `Closes #N`
- The `pr-submitted` label can be cleaned up manually or via automation
- **Automated release**: the `auto-release.yml` workflow runs automatically and:
  1. Determines the semver bump from the PR title prefix (`feat:` → minor, `fix:`/`docs:`/`chore:` → patch, `BREAKING CHANGE` or `!:` → major)
  2. Promotes the `[Unreleased]` entries in `CHANGELOG.md` to the new version
  3. Commits the changelog update and creates a git tag
  4. The tag push triggers `release.yml` which creates the GitHub Release
- Because releases are automated, agents must ensure `CHANGELOG.md` entries under `[Unreleased]` are accurate — they become the release notes

## 9. Error Handling

### If the issue is unclear

Do NOT guess. Comment on the issue asking for clarification:

```bash
gh issue comment <number> --body "Clarification needed: <specific question>"
gh issue edit <number> --add-label "blocked" --remove-label "in-progress"
```

### If you discover additional work

Open a new issue instead of scope-creeping the current PR:

```bash
gh issue create --title "chore: <discovered work>" --body "<details>" --label "triage"
```

### If CI fails after push

1. Read the CI failure logs
2. Fix the issue locally
3. Push the fix as an additional commit (do not force-push)
4. Comment on the PR explaining the fix

### If there are merge conflicts

1. Rebase on latest `main`:
   ```bash
   git fetch origin main
   git rebase origin/main
   ```
2. Resolve conflicts preserving the intent of both changes
3. Force-push the rebased branch:
   ```bash
   git push --force-with-lease
   ```

## 10. What NOT To Do

### Human-Only Actions (NEVER do these)

- **Do NOT approve issues** — moving an issue from `triage` to `approved` is the human Overseer's exclusive responsibility. You must never apply the `approved` label, even if you created the issue.
- **Do NOT merge your own PRs** — merging is the human Overseer's exclusive responsibility. Never merge, enable auto-merge, or request auto-merge on any PR you created.
- **Do NOT approve your own PRs** — never submit an approving review on your own PR.
- **Do NOT manually create releases or tags** — releases are automated via `auto-release.yml` on PR merge.
- **Do NOT create PRs without a linked, approved issue** — every PR must reference an issue using `Closes #N` in the title or body. The `pr-gate.yml` required status check will block merge if this is missing or the issue was never approved.

### Scope & Safety

- Do NOT work on issues without the `approved` label
- Do NOT modify CI workflows unless the issue specifically requests it
- Do NOT commit secrets, personal paths, or machine-specific configuration
- Do NOT create `~/.aws/` directories without mode `700` (use `mkdir -p ~/.aws && chmod 700 ~/.aws`)
- Do NOT write `~/.aws/config` or `~/.aws/active_profile` without setting `chmod 600` immediately after
- Do NOT add dependencies without adding them to the `Brewfile`
- Do NOT make unrelated changes in the same PR
- Do NOT force-push unless rebasing to resolve conflicts

## 11. Enforcement

Issue linkage and approval are enforced at multiple layers. Even in interactive sessions (e.g., the user asks you to implement something directly), you must create an issue first and wait for approval before creating a branch or PR.

### Server-Side: PR Gate (cannot be bypassed)

The `pr-gate.yml` workflow runs on every PR targeting `main` and is a **required status check** in the branch ruleset. It:

1. Parses the PR title and body for `Closes #N`, `Fixes #N`, or `Resolves #N`
2. Looks up each linked issue via the GitHub API
3. Checks if the issue currently has or historically had the `approved` label
4. **Fails the check** if no linked issue is found or none were ever approved

Because this is a required status check, the PR cannot be merged until it passes.

### Client-Side: Git Hooks (convenience, bypassable)

Git hooks in `.github/hooks/` catch mistakes before they reach CI:

- **`pre-commit`**: Blocks direct commits on `main` (exceptions: merge commits, automated release commits)
- **`commit-msg`**: Rejects commits that don't contain `Closes #N`, `Fixes #N`, `Resolves #N`, or `Refs #N`
- **`pre-push`**: Rejects pushes from branches that don't match the naming convention (`agent/<number>-<slug>`, `feat/<slug>`, `fix/<slug>`, `docs/<slug>`, `chore/<slug>`)

These can be skipped with `--no-verify`, which is fine because the server-side gate catches it.

Install hooks:
```bash
bash .github/hooks/install.sh
```

---
name: issue-lifecycle
description: Label-based issue workflow from triage through completion
license: MIT
metadata:
  workflow: github
  audience: agents-and-maintainers
---

# Issue Lifecycle

This project uses a label-based lifecycle to track issues from submission through completion. AI agents and human contributors both follow this flow.

## State Labels

Issues progress through these states:

```
triage → approved → in-progress → pr-submitted → (closed)
                  ↘ blocked ↗
```

**`triage`** — Default state for all new issues. Needs human review.

**`approved`** — Maintainer has reviewed and approved. An AI agent may now pick this up and begin work. This is the human gate — no work starts without explicit approval.

**`in-progress`** — An agent or contributor is actively working on this issue. A branch exists and commits are being made.

**`pr-submitted`** — A pull request has been opened. Awaiting review and merge.

**`blocked`** — Work cannot proceed. The issue needs clarification, has an unresolved dependency, or is waiting on an external factor. A comment should explain the blocker.

## Priority Labels

Applied during triage to signal urgency:

- **`p0-critical`** — Breaks install/uninstall for all users. Fix immediately.
- **`p1-high`** — Significant bug or highly requested feature. Next up.
- **`p2-medium`** — Normal priority. Standard queue.
- **`p3-low`** — Nice to have. Work on when bandwidth allows.

## Type Labels

Applied during triage (matches issue templates):

- **`bug`** — Something is broken
- **`enhancement`** — New feature or improvement
- **`documentation`** — Docs-only change
- **`maintenance`** — CI, dependencies, refactoring

## How It Works

### For the Maintainer (Overseer)

1. New issue arrives with `triage` label (auto-applied)
2. Review the issue: is it valid, clear, and in scope?
3. Add a priority label (`p0` through `p3`) and type label (`bug`, `enhancement`, etc.)
4. When ready for work: replace `triage` with `approved`
5. An AI agent will pick it up, implement the change, and submit a PR
6. Review the PR, request changes if needed, and merge when satisfied

### For the AI Agent (Polecat)

> **Hard rule**: The agent must NEVER approve issues, merge PRs, or approve its own PRs. These are exclusively human actions.

1. Find issues with the `approved` label — never apply this label yourself
2. Follow the full workflow in the `sdlc-agent` skill
3. Manage labels as you progress: `in-progress` → `pr-submitted` (remove `approved` when starting work)
4. If blocked, label as `blocked` and comment with the specific blocker

### For Human Contributors

1. Fork the repo and work on issues labeled `approved` (or your own issues)
2. Follow `CONTRIBUTING.md` for development workflow
3. Label management is optional for external contributors — the maintainer handles it

## Label Reference

### State Labels (mutually exclusive)

| Label | Applied By | Meaning |
|-------|-----------|---------|
| `triage` | Auto (workflow) | New issue, needs review |
| `approved` | Maintainer | Ready for agent/contributor work |
| `in-progress` | Agent/contributor | Actively being worked on |
| `pr-submitted` | Agent/contributor | PR is open |
| `blocked` | Anyone | Cannot proceed |

### Priority Labels (pick one)

| Label | Meaning |
|-------|---------|
| `p0-critical` | Blocks all users |
| `p1-high` | Important, do next |
| `p2-medium` | Normal queue |
| `p3-low` | When bandwidth allows |

### Type Labels (pick one)

| Label | Meaning |
|-------|---------|
| `bug` | Something is broken |
| `enhancement` | New feature or improvement |
| `documentation` | Docs change only |
| `maintenance` | CI, deps, refactoring |

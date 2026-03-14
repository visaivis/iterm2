# Agent Skills

This directory contains reusable skills for AI coding agents. Skills are written in a platform-agnostic format compatible with OpenCode, Claude, and other AI agents that support the skill pattern.

## Structure

```
.agents/
└── skills/
    ├── sdlc-agent/
    │   └── SKILL.md          # Issue-to-PR workflow
    └── issue-lifecycle/
        └── SKILL.md          # Label-based issue states
```

## What are Skills?

Skills are markdown files with YAML frontmatter that define reusable behavior for AI agents. They're discovered automatically by compatible agents and loaded on-demand.

### Compatibility

This `.agents/` location works with:
- **OpenCode** — reads from `.opencode/skills/`, `.agents/skills/`, and `.claude/skills/`
- **Claude** — reads from `.claude/skills/` and `.agents/skills/`
- **Other agents** — most modern AI coding agents support the `.agents/` convention

## Available Skills

### `sdlc-agent`

Complete issue-to-PR workflow for AI agents working on approved issues. Covers:
- Issue intake and approval verification
- Branch naming conventions
- Implementation scope discipline
- Commit conventions and validation
- PR creation and post-merge automation

Load this skill when starting work on an issue.

### `issue-lifecycle`

Label-based issue workflow from triage through completion. Covers:
- State transitions (`triage` → `approved` → `in-progress` → `pr-submitted`)
- Priority labels (`p0-critical` through `p3-low`)
- Type labels (`bug`, `enhancement`, `documentation`, `maintenance`)
- Human vs agent responsibilities

Load this skill when managing issue labels or understanding the project workflow.

## How to Use

### OpenCode

Skills are automatically discovered. Agents see them in the `skill` tool:

```
Use skill: sdlc-agent
```

Or in code:
```typescript
skill({ name: "sdlc-agent" })
```

### Claude

Load a skill by referencing it:

```
Load the sdlc-agent skill
```

### Other Agents

Most modern AI coding agents will discover and load skills from `.agents/skills/*/SKILL.md` automatically. Refer to your agent's documentation for specific syntax.

## Creating New Skills

To add a new skill:

1. Create a directory: `.agents/skills/<name>/`
2. Create `SKILL.md` with YAML frontmatter:
   ```yaml
   ---
   name: my-skill
   description: Brief description (1-1024 chars)
   license: MIT
   metadata:
     key: value
   ---
   
   # Skill content here
   ```

3. Name must match `^[a-z0-9]+(-[a-z0-9]+)*$` (lowercase, hyphens only)
4. Name must match the directory name

## Backward Compatibility

The old `.github/skills/` location is deprecated but still present for reference. All new skills should be created in `.agents/skills/` for maximum compatibility.

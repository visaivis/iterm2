# Agent Secret Management

This guide covers how AI agents (Warp, opencode, etc.) securely access secrets for project workflows — GitHub SDLC automation, CI/CD tokens, API keys, and other integrations.

## Why This Architecture

AI agents need secrets to automate workflows on your behalf — creating branches, managing issues, opening PRs. But agents should never have access beyond what their specific project requires. The architecture enforces three security principles:

1. **Vault-per-project isolation** — each project gets its own 1Password vault containing only the secrets that project needs. An agent working on Project A cannot read secrets for Project B.

2. **No plaintext secrets anywhere** — the 1Password service account token (the one secret that bootstraps everything) is stored in macOS Keychain, encrypted at rest and protected by system authentication. All other secrets are resolved at runtime via `op://` references.

3. **Least-privilege scoping** — GitHub fine-grained PATs are scoped to a single repository with only the permissions the agent needs. The agent cannot modify branch protection, merge PRs, or access other repos.

## Security Model

```
┌─────────────────────────────────────────────────────────────┐
│  macOS Keychain: agent-secrets.keychain-db                   │
│  (dedicated keychain — isolated from login keychain)         │
│  └── OP_SERVICE_ACCOUNT_TOKEN                               │
└──────────────────────┬──────────────────────────────────────┘
                       │ retrieved at runtime
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  1Password Service Account (scoped to one vault)            │
│  └── authenticates `op` CLI                                 │
└──────────────────────┬──────────────────────────────────────┘
                       │ op run resolves op:// references
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  1Password Vault: "iterm2-agents"                           │
│  ├── iterm2-agent-github-pat  (GH_TOKEN)                   │
│  ├── some-api-key             (SOME_API_KEY)                │
│  └── ...future secrets                                      │
└──────────────────────┬──────────────────────────────────────┘
                       │ injected as env vars
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  Agent Process (warp, opencode, etc.)                       │
│  └── sees GH_TOKEN, SOME_API_KEY as env vars                │
│      never sees raw service account token                   │
│      cannot access other vaults                             │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- [1Password](https://1password.com/) account (Individual or Teams)
- [1Password CLI](https://developer.1password.com/docs/cli/get-started/) (`op`) installed: `brew install --cask 1password-cli`
- [GitHub CLI](https://cli.github.com/) (`gh`) installed: `brew install gh`
- macOS with Keychain Access

## Quick Start

If you're setting this up for the first time, run through these steps in order:

```bash
# 1. Create a 1Password vault for your project (via 1password.com UI)
# 2. Create a GitHub fine-grained PAT (via github.com UI)
# 3. Store the PAT in the vault (via 1password.com UI)
# 4. Create a 1Password service account scoped to the vault (via 1password.com UI)
# 5. Create a dedicated keychain for agent secrets:
security create-keychain -p "" agent-secrets.keychain-db

# 6. Store the service account token in the dedicated keychain:
security add-generic-password -a "op-service-account" -s "iterm2-agents" -w agent-secrets.keychain-db

# 7. Create the env file with op:// references:
cat > .env.agent <<'EOF'
GH_TOKEN=op://iterm2-agents/iterm2-agent-github-pat/credential
EOF

# 8. Launch your agent:
OP_SERVICE_ACCOUNT_TOKEN=$(security find-generic-password -a "op-service-account" -s "iterm2-agents" -w agent-secrets.keychain-db) \
  op run --env-file=.env.agent -- opencode
```

The sections below walk through each step in detail.

## Step 1: Create a 1Password Vault

Each project/repo gets its own vault to isolate secrets.

1. Go to [1password.com](https://1password.com) and sign in
2. Click **New Vault**
3. Name it after your project: `iterm2-agents` (or `<project>-agents`)
4. Description: "Secrets for AI agent workflows on the iterm2 repo"

This vault will hold all secrets the agent needs for this project — GitHub tokens, API keys, webhook secrets, etc.

## Step 2: Create GitHub Fine-Grained PATs

You need two PATs with different scopes. Create both at [github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new).

### Agent PAT (for SDLC automation)

This is the token agents use for day-to-day work — creating branches, managing issues, opening PRs.

- **Name**: `iterm2-agent`
- **Expiration**: 90 days (set a calendar reminder to rotate)
- **Repository access**: Only select repositories → your repo
- **Permissions**:
  - Contents: **Read and write** (push branches)
  - Issues: **Read and write** (comments, labels)
  - Pull requests: **Read and write** (create PRs)
  - Metadata: **Read** (auto-selected)

What the agent **cannot** do with this token:
- Push to `main` (blocked by branch ruleset — agent is not admin)
- Change branch protection or rulesets (no Administration scope)
- Access other repositories (scoped to one repo)

### Release PAT (for CI auto-release workflow)

This token is used by the `auto-release.yml` GitHub Actions workflow to push changelog commits and tags to `main`.

- **Name**: `iterm2-release-bot`
- **Expiration**: 90 days
- **Repository access**: Only select repositories → your repo
- **Permissions**:
  - Contents: **Read and write**
  - Metadata: **Read** (auto-selected)

This token is stored as a **GitHub Actions secret** (not in 1Password) because it's consumed by CI, not by local agents:

```bash
gh secret set RELEASE_TOKEN --repo <owner>/<repo>
# Paste the token when prompted (input is hidden)
```

## Step 3: Store the Agent PAT in 1Password

1. Open 1Password and navigate to your project vault (`iterm2-agents`)
2. Click **New Item** → **Password** (or **API Credential** if available)
3. Fill in:
   - **Title**: `iterm2-agent-github-pat`
   - **Password / Credential**: paste the agent PAT
4. Add custom fields for tracking:
   - `expires`: the expiration date
   - `scopes`: `contents:rw, issues:rw, pull_requests:rw, metadata:r`
   - `repository`: `<owner>/<repo>`
5. Save

The `op://` reference for this item will be:
```
op://iterm2-agents/iterm2-agent-github-pat/password
```

> **Note**: The field name in the `op://` URI depends on the item type. For **Password** items, use `password`. For **API Credential** items, use `credential`. Check the field name in 1Password if unsure.

## Step 4: Create a 1Password Service Account

Service accounts restrict CLI access to specific vaults. The agent authenticates as the service account — not as you — so it can only see secrets in the vaults you grant.

1. Go to [1password.com](https://1password.com) → **Developer** → **Infrastructure Secrets** → **Service Accounts**
2. Click **New Service Account**
3. Configure:
   - **Name**: `warp-agent` (or `<project>-agent`)
   - **Vault access**: Select **only** your project vault (`iterm2-agents`)
   - **Permissions**: Read items (agents should not write to the vault)
4. Click **Create** and copy the generated token

> **Important**: This token is shown only once. If you lose it, you'll need to create a new service account.

## Step 5: Create a Dedicated Keychain

Agents should not have access to your login keychain (which contains Wi-Fi passwords, browser certificates, and other personal credentials). Create a dedicated keychain that holds only agent secrets:

```bash
security create-keychain -p "" agent-secrets.keychain-db
```

This creates an empty, unlocked keychain file at `~/Library/Keychains/agent-secrets.keychain-db`. The `-p ""` sets an empty password — the keychain is protected by macOS file permissions, and the secrets inside are still encrypted.

## Step 6: Store the Service Account Token

Store the 1Password service account token in the dedicated keychain:

```bash
security add-generic-password \
  -a "op-service-account" \
  -s "iterm2-agents" \
  -w \
  agent-secrets.keychain-db
```

You will be prompted to enter the token (input is hidden). The parameters:
- `-a` (account): identifier for the credential type
- `-s` (service): your vault/project name (used to look it up later)
- `-w`: prompt for the password interactively (not passed on the command line)
- `agent-secrets.keychain-db`: the target keychain (not the default login keychain)

To verify it was stored:

```bash
security find-generic-password -a "op-service-account" -s "iterm2-agents" agent-secrets.keychain-db
```

This prints metadata (not the token itself). To retrieve the token value (used in scripts):

```bash
security find-generic-password -a "op-service-account" -s "iterm2-agents" -w agent-secrets.keychain-db
```

## Step 7: Create the Environment Reference File

Create `.env.agent` in the project root. This file contains `op://` references — not actual secrets — so it is safe to commit.

```bash
cat > .env.agent <<'EOF'
GH_TOKEN=op://iterm2-agents/iterm2-agent-github-pat/password
EOF
```

The format is:
```
ENV_VAR=op://<vault-name>/<item-title>/<field-name>
```

As you add more integrations, add more lines:
```
GH_TOKEN=op://iterm2-agents/iterm2-agent-github-pat/password
SLACK_WEBHOOK=op://iterm2-agents/slack-webhook/password
SOME_API_KEY=op://iterm2-agents/some-api-key/password
```

## Step 8: Launch the Agent

Combine Keychain retrieval with `op run` to launch the agent with all secrets injected:

```bash
OP_SERVICE_ACCOUNT_TOKEN=$(security find-generic-password -a "op-service-account" -s "iterm2-agents" -w agent-secrets.keychain-db) \
  op run --env-file=.env.agent -- opencode
```

What happens:
1. `security` retrieves the service account token from Keychain
2. `OP_SERVICE_ACCOUNT_TOKEN` authenticates the `op` CLI as the service account
3. `op run` resolves all `op://` references in `.env.agent` into real values
4. The agent process receives secrets as environment variables
5. When the process exits, the environment variables are gone

### Shell Alias (optional)

Add to your `~/.zshrc` or `~/.modern-terminal/custom.zsh` for convenience:

```bash
agent-opencode() {
  OP_SERVICE_ACCOUNT_TOKEN=$(security find-generic-password -a "op-service-account" -s "iterm2-agents" -w agent-secrets.keychain-db) \
    op run --env-file="${1:-.env.agent}" -- opencode
}
```

Usage:
```bash
agent-opencode                    # Uses .env.agent in current dir
agent-opencode .env.agent.dev     # Uses a different env file
```

## Adding New Secrets

When a new integration requires a secret:

1. **Create the secret** (API key, token, etc.) from the provider
2. **Store in 1Password** → your project vault → new Password item
3. **Add the `op://` reference** to `.env.agent`:
   ```
   NEW_SECRET=op://iterm2-agents/new-item-title/password
   ```
4. **Restart the agent** — `op run` resolves references at launch time

No code changes, no plaintext, no environment variable exports.

## Applying to Other Projects

To set up agent secrets for a new project:

1. Create a new 1Password vault: `<project>-agents`
2. Create a new service account scoped to that vault
3. Store the service account token in the dedicated keychain:
   ```bash
   security add-generic-password -a "op-service-account" -s "<project>-agents" -w agent-secrets.keychain-db
   ```
4. Create the project's `.env.agent` with `op://` references
5. Launch with the project-specific Keychain entry:
   ```bash
   OP_SERVICE_ACCOUNT_TOKEN=$(security find-generic-password -a "op-service-account" -s "<project>-agents" -w agent-secrets.keychain-db) \
     op run --env-file=.env.agent -- opencode
   ```

All projects share the same `agent-secrets.keychain-db` keychain but use different `-s` (service) names. Each is fully isolated — different vault, different service account, different Keychain entry.

## Token Rotation

Fine-grained PATs expire. When a token nears expiration:

1. Create a new PAT on GitHub with the same scopes
2. Update the item in 1Password (paste new token)
3. If it's the release PAT: also update the GitHub Actions secret:
   ```bash
   gh secret set RELEASE_TOKEN --repo <owner>/<repo>
   ```
4. No changes needed to `.env.agent` or the Keychain — the `op://` reference resolves to the updated value automatically

## Troubleshooting

### `op` says "not signed in"
Make sure `OP_SERVICE_ACCOUNT_TOKEN` is set. The service account token authenticates the CLI — it does not use your desktop app sign-in.

### `op run` says "could not resolve" an `op://` reference
Check that:
- The vault name in the URI matches exactly (case-sensitive)
- The item title matches exactly
- The field name is correct (`password` for Password items, `credential` for API Credential items)
- The service account has access to the vault

### `security` command hangs or prompts for password
If the dedicated keychain is locked, unlock it first:
```bash
security unlock-keychain agent-secrets.keychain-db
```
The keychain created with `-p ""` should remain unlocked during your session, but macOS may lock it after a reboot or timeout.

### Agent can push to `main` unexpectedly
The agent PAT should belong to a non-admin user, or the branch ruleset should block non-bypass actors. Verify:
```bash
gh api repos/<owner>/<repo>/rulesets --jq '.[].bypass_actors'
```

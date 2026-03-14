# AWS Bedrock + OpenCode Setup

> **Why?** We have AWS Bedrock access through the `WFS-Architects-RD` account. This setup uses it as the default LLM provider for OpenCode — no API keys required. Authentication is handled via AWS SSO through Microsoft Entra ID.

---

## How It Works

The installer automatically:
1. Installs `~/bin/bedrock-auth` — your SSO authentication helper
2. Bootstraps `~/.aws/config` with the `WFS-Architects-RD` profile and `my-sso` session
3. Installs `~/.config/opencode/opencode.json` pre-configured to use `amazon-bedrock`
4. Adds `bedrock-login`, `bedrock-logout`, and `bedrock-status` shell aliases

---

## Prerequisites

- **AWS CLI v2** — installed automatically via `Brewfile` (`brew install awscli`)
- Access to the `WFS-Architects-RD` AWS account (via Microsoft Entra ID group membership)

---

## Step 1 — Authenticate

After running `./install.sh`, log in with:

```sh
bedrock-login
```

This opens your browser to the Microsoft Entra ID SSO portal. Approve the login request, then return to your terminal. Your session is cached for 8 hours.

```sh
# Check auth status
bedrock-status

# Log out
bedrock-logout
```

The `~/bin/bedrock-auth` script manages SSO authentication against the `WFS-Architects-RD` profile (`my-sso` session, account `711387094947`, role `WFSPowerUserAccess`). The installer bootstraps `~/.aws/config` automatically — you should not need to edit it manually.

---

## Step 2 — Launch OpenCode

OpenCode is pre-configured to use Bedrock. Launch it directly:

```sh
opencode
```

Or via the AI workspace tmux layout:
```sh
ai-workspace    # opens OpenCode in its own tmux pane
```

The default model is **Claude Sonnet 4.5** (`anthropic.claude-sonnet-4-5-20250929-v1:0`). Type `/models` inside the TUI to switch models interactively.

---

## Model Recommendations

| Use Case | Recommended Model | Bedrock ID |
|---|---|---|
| General coding | Claude Sonnet 4.5 | `anthropic.claude-sonnet-4-5-20250929-v1:0` |
| Complex architecture | Claude Opus 4.5 | `anthropic.claude-opus-4-5-20251101-v1:0` |
| Quick questions | Claude 3.5 Haiku | `anthropic.claude-3-5-haiku-20241022-v1:0` |
| Code generation | Devstral 2 123B | `mistral.devstral-2-123b` |
| Reasoning tasks | DeepSeek R1 | `deepseek.r1-v1:0` |
| Cost-sensitive | Amazon Nova Micro | `amazon.nova-micro-v1:0` |

To switch models in OpenCode, type `/models` in the TUI or update `~/.config/opencode/opencode.json`.

---

## Configuration

The installer places the OpenCode config at `~/.config/opencode/opencode.json`:

```json
{
  "provider": "amazon-bedrock",
  "model": "anthropic.claude-sonnet-4-5-20250929-v1:0",
  "small_model": "anthropic.claude-3-5-haiku-20241022-v1:0",
  "providers": {
    "amazon-bedrock": {
      "region": "us-east-1",
      "profile": "WFS-Architects-RD"
    }
  }
}
```

---

## Troubleshooting

### "Unable to locate credentials"
Your SSO session has expired. Re-authenticate:
```sh
bedrock-login
```

### "Could not resolve credentials using profile"
Verify the profile exists:
```sh
bedrock-status
```
If missing, re-run `./install.sh` — it will append the profile without touching existing config.

### Model returns an error
- Confirm the model is enabled in your region:
  ```sh
  aws bedrock list-foundation-models --region us-east-1 --profile WFS-Architects-RD \
    --query "modelSummaries[?modelLifecycle.status=='ACTIVE'].modelId" --output table
  ```
- Some models (especially Anthropic) require a one-time access request in the [Bedrock console](https://console.aws.amazon.com/bedrock/).

### OpenCode shows "no provider configured"
Verify `~/.config/opencode/opencode.json` exists:
```sh
cat ~/.config/opencode/opencode.json
```
If missing, copy it from `config/opencode/opencode.json` in this repo.

---

## Quick Reference

```sh
# Authentication
bedrock-login              # Authenticate via Microsoft Entra ID SSO
bedrock-status             # Check current auth status
bedrock-logout             # Clear SSO session

# OpenCode
opencode                   # Launch AI coding TUI
opencode -p "..."          # One-shot prompt
ai-workspace               # 3-pane tmux layout with OpenCode

# List available models
aws bedrock list-foundation-models --region us-east-1 --profile WFS-Architects-RD \
  --query "modelSummaries[?modelLifecycle.status=='ACTIVE'].modelId" --output table
```

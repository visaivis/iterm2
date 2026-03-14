#!/usr/bin/env bash
###############################################################################
# bedrock-auth — AWS SSO authentication for Bedrock
#
# Manages the AWS SSO session that gives OpenCode access to Amazon Bedrock
# models. Authenticates via Microsoft Entra ID SSO, then lets you pick which
# AWS account and role to work with.
#
# Usage:
#   bedrock-auth login      Authenticate via Microsoft Entra ID SSO (then pick account)
#   bedrock-auth select     Pick AWS account/role (reuses existing SSO session)
#   bedrock-auth logout     Clear SSO session
#   bedrock-auth status     Show current AWS identity and session state
#
# The installer copies this script to ~/bin/bedrock-auth and adds
# bedrock-login / bedrock-select / bedrock-logout / bedrock-status aliases.
###############################################################################
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
SSO_SESSION="${SSO_SESSION:-my-sso}"
SSO_START_URL="https://wfscorp.awsapps.com/start"
# Default profile used for the initial post-login identity check.
# After cmd_select runs, the chosen profile name takes over.
AWS_PROFILE="${AWS_PROFILE:-WFS-Architects-RD}"

ACTIVE_PROFILE_FILE="$HOME/.aws/active_profile"
OC_CONFIG="$HOME/.config/opencode/opencode.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()   { echo -e "${CYAN}ℹ${NC}  $*"; }
ok()     { echo -e "${GREEN}✓${NC}  $*"; }
warn()   { echo -e "${YELLOW}⚠${NC}  $*"; }
err()    { echo -e "${RED}✗${NC}  $*" >&2; }
header() { echo -e "\n${BOLD}$*${NC}\n${DIM}$(printf '─%.0s' {1..50})${NC}"; }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
require_aws() {
  if ! command -v aws &>/dev/null; then
    err "AWS CLI is not installed."
    echo "  Install it: brew install awscli"
    exit 1
  fi
}

# Bootstrap ~/.aws/config with the SSO session + a default profile (idempotent)
bootstrap_aws_config() {
  mkdir -p ~/.aws
  chmod 700 ~/.aws
  if ! grep -q "\[sso-session ${SSO_SESSION}\]" ~/.aws/config 2>/dev/null; then
    {
      echo ""
      echo "[sso-session ${SSO_SESSION}]"
      echo "sso_start_url = ${SSO_START_URL}"
      echo "sso_region = ${AWS_REGION}"
      echo "sso_registration_scopes = sso:account:access"
    } >> ~/.aws/config
    chmod 600 ~/.aws/config
    ok "Created SSO session '${SSO_SESSION}' in ~/.aws/config"
  fi
  if ! grep -q "\[profile ${AWS_PROFILE}\]" ~/.aws/config 2>/dev/null; then
    {
      echo ""
      echo "[profile ${AWS_PROFILE}]"
      echo "sso_session = ${SSO_SESSION}"
      echo "sso_account_id = 711387094947"
      echo "sso_role_name = WFSPowerUserAccess"
      echo "region = ${AWS_REGION}"
    } >> ~/.aws/config
    chmod 600 ~/.aws/config
    ok "Created default profile '${AWS_PROFILE}' in ~/.aws/config"
  fi
}

# Read the SSO access token from the local cache
get_sso_token() {
  local cache_dir="$HOME/.aws/sso/cache"
  [[ -d "$cache_dir" ]] || { err "SSO cache not found — run: bedrock-login"; return 1; }
  SSO_CACHE_DIR="$cache_dir" python3 -c '
import json, os, glob
cache_dir = os.environ["SSO_CACHE_DIR"]
files = sorted(glob.glob(os.path.join(cache_dir, "*.json")),
               key=os.path.getmtime, reverse=True)
for path in files:
    try:
        with open(path) as f:
            d = json.load(f)
        if "accessToken" in d:
            print(d["accessToken"])
            raise SystemExit(0)
    except (json.JSONDecodeError, OSError):
        pass
raise SystemExit(1)
'
}

# Interactive list picker using fzf (installed) or numbered fallback
# Reads items from stdin; returns the selected line on stdout
pick_from_list() {
  local prompt="$1"
  if command -v fzf &>/dev/null; then
    fzf --prompt="${prompt} " --height=40% --border --no-sort
  else
    local -a items
    while IFS= read -r line; do items+=("$line"); done
    if [[ ${#items[@]} -eq 0 ]]; then return 1; fi
    local i=1
    for item in "${items[@]}"; do
      printf "  %d) %s\n" "$i" "$item" >&2
      i=$((i + 1))
    done
    printf "Enter number [1-%d]: " "${#items[@]}" >&2
    read -r choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#items[@]} )); then
      echo "${items[$((choice - 1))]}"
    else
      err "Invalid selection."; return 1
    fi
  fi
}

# Write a named AWS profile to ~/.aws/config (idempotent)
write_aws_profile() {
  local profile="$1" account_id="$2" role="$3"
  if grep -q "\[profile ${profile}\]" ~/.aws/config 2>/dev/null; then
    ok "Profile '${profile}' already in ~/.aws/config"
    return
  fi
  {
    echo ""
    echo "[profile ${profile}]"
    echo "sso_session = ${SSO_SESSION}"
    echo "sso_account_id = ${account_id}"
    echo "sso_role_name = ${role}"
    echo "region = ${AWS_REGION}"
  } >> ~/.aws/config
  chmod 600 ~/.aws/config
  ok "Created profile '${profile}' in ~/.aws/config"
}

# Persist the active profile so new shells pick it up via aws.zsh
write_active_profile() {
  local profile="$1"
  echo "$profile" > "$ACTIVE_PROFILE_FILE"
  chmod 600 "$ACTIVE_PROFILE_FILE"
  ok "Saved active profile: ${BOLD}${profile}${NC} → ~/.aws/active_profile"
}

# Update OpenCode config to use the chosen profile
update_opencode_profile() {
  local profile="$1"
  [[ -f "$OC_CONFIG" ]] || return 0
  OC_PROFILE="$profile" OC_PATH="$OC_CONFIG" python3 -c '
import json, os
path, profile = os.environ["OC_PATH"], os.environ["OC_PROFILE"]
with open(path) as f:
    d = json.load(f)
d.setdefault("provider", {}).setdefault("amazon-bedrock", {}).setdefault("options", {})["profile"] = profile
with open(path, "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")
'
  ok "Updated OpenCode config: provider profile → '${profile}'"
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------
cmd_login() {
  header "AWS Bedrock Login (via Microsoft Entra ID SSO)"
  require_aws
  bootstrap_aws_config

  info "Starting SSO login for session '${SSO_SESSION}'…"
  info "Your browser will open — approve the Microsoft Entra ID request."
  echo ""
  aws sso login --sso-session "${SSO_SESSION}"

  echo ""
  ok "Authenticated. Verifying identity…"
  aws sts get-caller-identity --profile "${AWS_PROFILE}" --output table

  # Run the account picker so the user chooses which account to target
  cmd_select
}

cmd_select() {
  header "Select AWS Account"
  require_aws

  local token
  token=$(get_sso_token) || { err "No valid SSO session — run: bedrock-login"; exit 1; }

  # ── Accounts ──────────────────────────────────────────────────────────────
  info "Fetching available accounts…"
  local accounts_json
  accounts_json=$(aws sso list-accounts \
    --access-token "$token" --region "$AWS_REGION" \
    --output json 2>/dev/null) || {
    err "Could not list accounts — SSO session may be expired. Run: bedrock-login"
    exit 1
  }

  local account_count
  account_count=$(ACCOUNTS_JSON="$accounts_json" python3 -c '
import json, os
print(len(json.loads(os.environ["ACCOUNTS_JSON"])["accountList"]))
')

  local account_lines
  account_lines=$(ACCOUNTS_JSON="$accounts_json" python3 -c '
import json, os
d = json.loads(os.environ["ACCOUNTS_JSON"])
for a in sorted(d["accountList"], key=lambda x: x["accountName"]):
    print(a["accountId"] + "  " + a["accountName"])
')

  local selected_account_line
  if [[ "$account_count" -eq 1 ]]; then
    selected_account_line="$account_lines"
    info "One account available — using it automatically."
  else
    echo ""
    selected_account_line=$(echo "$account_lines" \
      | pick_from_list "Select AWS account:") || { info "No account selected."; return 0; }
    [[ -n "$selected_account_line" ]] || { info "No account selected."; return 0; }
  fi

  local selected_id selected_name
  selected_id=$(echo "$selected_account_line" | awk '{print $1}')
  selected_name=$(echo "$selected_account_line" | awk '{$1=""; sub(/^ +/, ""); print}')

  # ── Roles ──────────────────────────────────────────────────────────────────
  local roles_json
  roles_json=$(aws sso list-account-roles \
    --access-token "$token" --account-id "$selected_id" \
    --region "$AWS_REGION" --output json 2>/dev/null) || {
    err "Could not list roles for account $selected_id."
    exit 1
  }

  local role_count
  role_count=$(ROLES_JSON="$roles_json" python3 -c '
import json, os
print(len(json.loads(os.environ["ROLES_JSON"])["roleList"]))
')

  local role_lines
  role_lines=$(ROLES_JSON="$roles_json" python3 -c '
import json, os
d = json.loads(os.environ["ROLES_JSON"])
for r in sorted(d["roleList"], key=lambda x: x["roleName"]):
    print(r["roleName"])
')

  local selected_role
  if [[ "$role_count" -eq 1 ]]; then
    selected_role="$role_lines"
    info "One role available: ${BOLD}${selected_role}${NC}"
  else
    echo ""
    selected_role=$(echo "$role_lines" \
      | pick_from_list "Select role for ${selected_name}:") || { info "No role selected."; return 0; }
    [[ -n "$selected_role" ]] || { info "No role selected."; return 0; }
  fi

  # ── Profile ────────────────────────────────────────────────────────────────
  # Derive a safe profile name from the account name
  local profile_name
  profile_name=$(echo "$selected_name" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')

  write_aws_profile  "$profile_name" "$selected_id" "$selected_role"
  write_active_profile "$profile_name"
  update_opencode_profile "$profile_name"

  echo ""
  ok "Account  : ${BOLD}${selected_name}${NC} (${selected_id})"
  ok "Role     : ${BOLD}${selected_role}${NC}"
  ok "Profile  : ${BOLD}${profile_name}${NC}"
  echo ""
  info "OpenCode will use Bedrock via profile '${profile_name}' automatically."
  info "New terminal windows will also pick this up via ~/.aws/active_profile."
  warn "To activate in your ${BOLD}current${NC} shell session:"
  echo "  export AWS_PROFILE=${profile_name}"
}

cmd_logout() {
  header "AWS Bedrock Logout"
  require_aws
  info "Clearing SSO session '${SSO_SESSION}'…"
  aws sso logout
  ok "Logged out. Run ${BOLD}bedrock-login${NC} to re-authenticate."
}

cmd_status() {
  header "AWS Bedrock Auth Status"
  require_aws
  info "Profile : ${AWS_PROFILE}"
  info "Region  : ${AWS_REGION}"
  echo ""
  if aws sts get-caller-identity --profile "${AWS_PROFILE}" &>/dev/null; then
    ok "Authenticated:"
    aws sts get-caller-identity --profile "${AWS_PROFILE}" --output table
    echo ""
    info "Session token expiry:"
    aws configure list --profile "${AWS_PROFILE}" 2>/dev/null | grep -i 'session\|expir' || true
  else
    warn "Session expired or not authenticated."
    echo "  Run: bedrock-login"
    exit 1
  fi
}

case "${1:-}" in
  login)   cmd_login  ;;
  select)  cmd_select ;;
  logout)  cmd_logout ;;
  status)  cmd_status ;;
  *)
    echo "Usage: bedrock-auth {login|select|logout|status}"
    echo ""
    echo "  login   — Authenticate via Microsoft Entra ID SSO (then pick account)"
    echo "  select  — Pick AWS account/role (reuses existing SSO session)"
    echo "  logout  — Clear SSO session"
    echo "  status  — Show current AWS identity and session state"
    exit 1
    ;;
esac

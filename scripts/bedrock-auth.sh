#!/usr/bin/env bash
###############################################################################
# bedrock-auth.sh — AWS SSO authentication for Bedrock
#
# Manages the AWS SSO session that gives OpenCode and iTerm2 access to
# Amazon Bedrock models via the WFS-Architects-RD account.
#
# Usage:
#   bedrock-auth login      Authenticate via Microsoft Entra ID SSO
#   bedrock-auth logout     Clear SSO session
#   bedrock-auth status     Show current AWS identity and session state
#
# The installer copies this script to ~/bin/bedrock-auth and adds
# bedrock-login / bedrock-logout / bedrock-status shell aliases.
###############################################################################
set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-WFS-Architects-RD}"
AWS_REGION="${AWS_REGION:-us-east-1}"
SSO_SESSION="${SSO_SESSION:-my-sso}"
SSO_START_URL="https://wfscorp.awsapps.com/start"
SSO_ACCOUNT_ID="711387094947"
SSO_ROLE_NAME="WFSPowerUserAccess"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()    { echo -e "${CYAN}ℹ${NC}  $*"; }
ok()      { echo -e "${GREEN}✓${NC}  $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
err()     { echo -e "${RED}✗${NC}  $*" >&2; }
header()  { echo -e "\n${BOLD}$*${NC}\n${DIM}$(printf '─%.0s' {1..50})${NC}"; }

# ---------------------------------------------------------------------------
# Ensure AWS CLI is installed
# ---------------------------------------------------------------------------
require_aws() {
  if ! command -v aws &>/dev/null; then
    err "AWS CLI is not installed."
    echo "  Install it: brew install awscli"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Bootstrap ~/.aws/config with the SSO session + profile if missing
# ---------------------------------------------------------------------------
bootstrap_aws_config() {
  mkdir -p ~/.aws

  if ! grep -q "\[sso-session ${SSO_SESSION}\]" ~/.aws/config 2>/dev/null; then
    cat >> ~/.aws/config <<EOF

[sso-session ${SSO_SESSION}]
sso_start_url = ${SSO_START_URL}
sso_region = ${AWS_REGION}
sso_registration_scopes = sso:account:access
EOF
    ok "Created SSO session '${SSO_SESSION}' in ~/.aws/config"
  fi

  if ! grep -q "\[profile ${AWS_PROFILE}\]" ~/.aws/config 2>/dev/null; then
    cat >> ~/.aws/config <<EOF

[profile ${AWS_PROFILE}]
sso_session = ${SSO_SESSION}
sso_account_id = ${SSO_ACCOUNT_ID}
sso_role_name = ${SSO_ROLE_NAME}
region = ${AWS_REGION}
EOF
    ok "Created AWS profile '${AWS_PROFILE}' in ~/.aws/config"
  fi
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------
cmd_login() {
  header "AWS Bedrock Login (via Microsoft Entra ID SSO)"
  require_aws
  bootstrap_aws_config

  info "Starting SSO login for profile '${AWS_PROFILE}'…"
  info "Your browser will open — approve the Microsoft Entra ID request."
  echo ""
  aws sso login --sso-session "${SSO_SESSION}"

  echo ""
  ok "Authenticated. Verifying identity…"
  aws sts get-caller-identity --profile "${AWS_PROFILE}" --output table

  echo ""
  info "OpenCode will now use Bedrock models automatically."
  info "Tip: run ${BOLD}bedrock-status${NC} at any time to check your session."
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
    aws configure list --profile "${AWS_PROFILE}" 2>/dev/null | grep -i "session\|expir" || true
  else
    warn "Session expired or not authenticated."
    echo "  Run: bedrock-login"
    exit 1
  fi
}

case "${1:-}" in
  login)   cmd_login  ;;
  logout)  cmd_logout ;;
  status)  cmd_status ;;
  *)
    echo "Usage: bedrock-auth {login|logout|status}"
    echo ""
    echo "  login   — Authenticate via Microsoft Entra ID SSO"
    echo "  logout  — Clear SSO session"
    echo "  status  — Show current AWS identity and session state"
    exit 1
    ;;
esac

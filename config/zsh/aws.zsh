# AWS Configuration — Bedrock Provider Defaults
# Sets the default AWS profile and region for OpenCode Bedrock access.
# Run `bedrock-login` to authenticate via Microsoft Entra ID SSO.

# Set defaults only if not already defined in the user's environment
export AWS_PROFILE="${AWS_PROFILE:-WFS-Architects-RD}"
export AWS_REGION="${AWS_REGION:-us-east-1}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

# Bedrock auth helpers — delegate to ~/bin/bedrock-auth
if [[ -x "$HOME/bin/bedrock-auth" ]]; then
  alias bedrock-login='bedrock-auth login'
  alias bedrock-logout='bedrock-auth logout'
  alias bedrock-status='bedrock-auth status'
fi

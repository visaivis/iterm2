# AWS Configuration — Bedrock Provider Defaults
# Sets the default AWS profile and region for OpenCode Bedrock access.
# Run `bedrock-login` to authenticate, then `bedrock-select` to switch accounts.

# Use the last account chosen by bedrock-select, falling back to the default
if [[ -f "$HOME/.aws/active_profile" ]]; then
  export AWS_PROFILE="${AWS_PROFILE:-$(cat "$HOME/.aws/active_profile")}"
else
  export AWS_PROFILE="${AWS_PROFILE:-WFS-Architects-RD}"
fi
export AWS_REGION="${AWS_REGION:-us-east-1}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

# Bedrock auth helpers — delegate to ~/bin/bedrock-auth
if [[ -x "$HOME/bin/bedrock-auth" ]]; then
  alias bedrock-login='bedrock-auth login'
  alias bedrock-select='bedrock-auth select'
  alias bedrock-logout='bedrock-auth logout'
  alias bedrock-status='bedrock-auth status'
fi

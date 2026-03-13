#!/usr/bin/env bash
# Installs project git hooks from .github/hooks/ into .git/hooks/
#
# Usage: bash .github/hooks/install.sh

set -euo pipefail

HOOK_SOURCE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HOOK_SOURCE/../.." && pwd)"
HOOK_TARGET="$REPO_ROOT/.git/hooks"

if [ ! -d "$HOOK_TARGET" ]; then
  echo "ERROR: Not a git repository (missing .git/hooks/)"
  exit 1
fi

installed=0

for hook in "$HOOK_SOURCE"/*; do
  hook_name=$(basename "$hook")

  # Skip this install script
  if [ "$hook_name" = "install.sh" ]; then
    continue
  fi

  # Skip non-files
  if [ ! -f "$hook" ]; then
    continue
  fi

  cp "$hook" "$HOOK_TARGET/$hook_name"
  chmod +x "$HOOK_TARGET/$hook_name"
  echo "Installed: $hook_name"
  installed=$((installed + 1))
done

echo ""
echo "$installed hook(s) installed to .git/hooks/"
echo "To skip hooks on a per-command basis: --no-verify"

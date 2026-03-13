#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Modern Terminal Configuration - Uninstaller
# =============================================================================
# Reverses install.sh by reading the manifest and restoring backups.

BACKUP_BASE="$HOME/.terminal-config-backup"
CONFIG_DIR="$HOME/.modern-terminal"
ITERM_PROFILES_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
ZSHRC="$HOME/.zshrc"
SOURCE_LINE='[[ -f ~/.modern-terminal/init.zsh ]] && source ~/.modern-terminal/init.zsh'
SOURCE_COMMENT='# modern terminal config'

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# Flags
REMOVE_PACKAGES=false
DRY_RUN=false
BACKUP_ID=""

info()  { echo -e "${BLUE}ℹ${NC} $*"; }
ok()    { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC} $*"; }
err()   { echo -e "${RED}✗${NC} $*"; }
header(){ echo -e "\n${BOLD}${CYAN}$*${NC}"; echo -e "${DIM}$(printf '─%.0s' {1..60})${NC}"; }

confirm() {
  if $DRY_RUN; then return 0; fi
  echo -en "${YELLOW}?${NC} $1 ${DIM}[y/N]${NC} "
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

usage() {
  cat <<EOF
${BOLD}Modern Terminal Configuration - Uninstaller${NC}

${BOLD}Usage:${NC}
  ./uninstall.sh [options]

${BOLD}Options:${NC}
  --dry-run             Preview what would be restored/removed
  --remove-packages     Also uninstall Homebrew packages added by install.sh
  --backup-id <ID>      Use a specific backup (timestamp). Default: latest.
  -h, --help            Show this help message

${BOLD}What it does:${NC}
  1. Removes the source line from ~/.zshrc
  2. Removes the ~/.modern-terminal symlink
  3. Removes the iTerm2 Dynamic Profile
  4. Removes the ~/.tmux.conf symlink
  5. Removes the delta include from ~/.gitconfig
  6. Restores all backed-up files from ~/.terminal-config-backup/
  7. Optionally uninstalls Homebrew packages (--remove-packages)

${BOLD}Note:${NC}
  TPM and its plugins (~/.tmux/plugins/) are NOT removed automatically.
  The fzf-tab clone in the repo vendor/ directory is NOT removed.
  Shell history (zoxide db, fzf history) is NOT removed.
EOF
  exit 0
}

# =============================================================================
# Parse Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)           DRY_RUN=true ;;
    --remove-packages)   REMOVE_PACKAGES=true ;;
    --backup-id)         shift; BACKUP_ID="$1" ;;
    -h|--help)           usage ;;
    *) err "Unknown option: $1"; usage ;;
  esac
  shift
done

# =============================================================================
# Find Backup
# =============================================================================

header "Finding backup"

if [[ ! -d "$BACKUP_BASE" ]]; then
  err "No backups found at $BACKUP_BASE"
  err "Nothing to uninstall (was install.sh ever run?)"
  exit 1
fi

if [[ -n "$BACKUP_ID" ]]; then
  BACKUP_DIR="$BACKUP_BASE/$BACKUP_ID"
else
  # Find the latest backup
  BACKUP_ID=$(ls -1 "$BACKUP_BASE" | sort -r | head -1)
  BACKUP_DIR="$BACKUP_BASE/$BACKUP_ID"
fi

if [[ ! -d "$BACKUP_DIR" ]]; then
  err "Backup not found: $BACKUP_DIR"
  exit 1
fi

MANIFEST="$BACKUP_DIR/manifest.log"
if [[ ! -f "$MANIFEST" ]]; then
  err "No manifest found in backup: $MANIFEST"
  exit 1
fi

ok "Using backup: $BACKUP_ID"
info "Manifest: $MANIFEST"

# =============================================================================
# Preview
# =============================================================================

header "Uninstall Plan"

echo -e "  The following changes will be made:\n"
echo -e "  ${RED}▸${NC} Remove source line from ~/.zshrc"
echo -e "  ${RED}▸${NC} Remove symlink: ~/.modern-terminal"
echo -e "  ${RED}▸${NC} Remove iTerm2 Dynamic Profile: Modern Dark"
echo -e "  ${RED}▸${NC} Remove symlink: ~/.tmux.conf (if ours)"
echo -e "  ${RED}▸${NC} Remove delta include from ~/.gitconfig"
echo -e "  ${GREEN}▸${NC} Restore backed-up files from: ${DIM}$BACKUP_DIR${NC}"
$REMOVE_PACKAGES && echo -e "  ${RED}▸${NC} Uninstall Homebrew packages from Brewfile"
echo ""

if ! $DRY_RUN; then
  if ! confirm "Proceed with uninstall?"; then
    info "Uninstall cancelled."
    exit 0
  fi
fi

# =============================================================================
# 1. Remove source line from .zshrc
# =============================================================================

header "Cleaning ~/.zshrc"

if [[ -f "$ZSHRC" ]]; then
  if grep -qF "$SOURCE_LINE" "$ZSHRC"; then
    if $DRY_RUN; then
      info "Would remove source line and comment from .zshrc"
    else
      # Remove both the comment and the source line
      sed -i '' "/$SOURCE_COMMENT/d" "$ZSHRC"
      sed -i '' "\|$SOURCE_LINE|d" "$ZSHRC"
      # Remove trailing blank lines
      sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$ZSHRC"
      ok "Removed source line from .zshrc"
    fi
  else
    ok "Source line not found in .zshrc (already clean)"
  fi
fi

# =============================================================================
# 2. Remove ~/.modern-terminal symlink
# =============================================================================

header "Removing config symlink"

if [[ -L "$CONFIG_DIR" ]]; then
  if $DRY_RUN; then
    info "Would remove symlink: $CONFIG_DIR"
  else
    rm -f "$CONFIG_DIR"
    ok "Removed: $CONFIG_DIR"
  fi
elif [[ -e "$CONFIG_DIR" ]]; then
  warn "$CONFIG_DIR exists but is not a symlink. Leaving it alone."
else
  ok "$CONFIG_DIR already removed"
fi

# =============================================================================
# 3. Remove iTerm2 Dynamic Profile
# =============================================================================

header "Removing iTerm2 Dynamic Profile"

profile_file="$ITERM_PROFILES_DIR/modern-dark.json"
if [[ -f "$profile_file" ]]; then
  if $DRY_RUN; then
    info "Would remove: $profile_file"
  else
    rm -f "$profile_file"
    ok "Removed: Modern Dark profile"
  fi
else
  ok "Profile already removed"
fi

# =============================================================================
# 4. Remove tmux config symlink
# =============================================================================

header "Removing tmux configuration"

tmux_conf="$HOME/.tmux.conf"
if [[ -L "$tmux_conf" ]]; then
  if $DRY_RUN; then
    info "Would remove symlink: $tmux_conf"
  else
    rm -f "$tmux_conf"
    ok "Removed: ~/.tmux.conf symlink"
  fi
elif [[ -f "$tmux_conf" ]]; then
  warn "~/.tmux.conf exists but is not a symlink (may be user's own). Leaving it."
else
  ok "~/.tmux.conf already removed"
fi

# =============================================================================
# 5. Remove delta from gitconfig
# =============================================================================

header "Removing git delta config"

if git config --global --get-all include.path 2>/dev/null | grep -q "delta.gitconfig"; then
  if $DRY_RUN; then
    info "Would remove delta include from ~/.gitconfig"
  else
    git config --global --unset-all include.path ".*delta.gitconfig" 2>/dev/null || true
    ok "Removed delta include from ~/.gitconfig"
  fi
else
  ok "Delta include not found in ~/.gitconfig"
fi

# =============================================================================
# 6. Restore backed-up files
# =============================================================================

header "Restoring backups"

while IFS= read -r line; do
  # Skip comments and empty lines
  [[ "$line" =~ ^#.*$ ]] && continue
  [[ -z "$line" ]] && continue

  action="${line%% *}"
  rest="${line#* }"

  case "$action" in
    BACKUP)
      original="${rest%% *}"
      backup="${rest#* }"
      if [[ -f "$backup" ]]; then
        if $DRY_RUN; then
          info "Would restore: $backup → $original"
        else
          mkdir -p "$(dirname "$original")"
          cp -a "$backup" "$original"
          ok "Restored: ${DIM}$original${NC}"
        fi
      fi
      ;;
    MOVE)
      original="${rest%% *}"
      moved_to="${rest#* }"
      if [[ -e "$moved_to" ]] && [[ ! -e "$original" ]]; then
        if $DRY_RUN; then
          info "Would restore: $moved_to → $original"
        else
          mv "$moved_to" "$original"
          ok "Restored: ${DIM}$original${NC}"
        fi
      fi
      ;;
  esac
done < "$MANIFEST"

# =============================================================================
# 7. Optionally remove Homebrew packages
# =============================================================================

if $REMOVE_PACKAGES; then
  header "Uninstalling Homebrew packages"

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  BREWFILE="$SCRIPT_DIR/Brewfile"

  if [[ -f "$BREWFILE" ]]; then
    # Extract package names from Brewfile
    packages=()
    while IFS= read -r line; do
      if [[ "$line" =~ ^brew\ \"(.+)\" ]]; then
        packages+=("${BASH_REMATCH[1]}")
      fi
    done < "$BREWFILE"

    if [[ ${#packages[@]} -gt 0 ]]; then
      echo -e "  Packages to uninstall:"
      for pkg in "${packages[@]}"; do
        echo -e "    ${RED}▸${NC} $pkg"
      done
      echo ""

      if $DRY_RUN; then
        info "Would uninstall ${#packages[@]} packages"
      else
        if confirm "Uninstall these ${#packages[@]} packages?"; then
          for pkg in "${packages[@]}"; do
            brew uninstall "$pkg" 2>/dev/null && ok "Uninstalled: $pkg" || warn "Could not uninstall: $pkg"
          done
        else
          info "Skipped package removal"
        fi
      fi
    fi
  else
    warn "Brewfile not found at $BREWFILE"
  fi
fi

# =============================================================================
# Summary
# =============================================================================

header "Uninstall complete"

if $DRY_RUN; then
  info "This was a dry run. No changes were made."
else
  echo -e "
  ${GREEN}${BOLD}Done.${NC} Your terminal has been restored to its previous state.

  ${BOLD}Notes:${NC}
  • Restart your terminal for changes to take effect
  • Backups are still available at: ${DIM}$BACKUP_DIR${NC}
  • TPM plugins remain at: ${DIM}~/.tmux/plugins/${NC} (remove manually if desired)
  • To fully clean up backups: ${DIM}rm -rf $BACKUP_BASE${NC}
"
fi

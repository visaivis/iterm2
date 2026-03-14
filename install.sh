#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Modern Terminal Configuration - Installer
# =============================================================================
# Safe, non-destructive, reversible installation.
# Run with --dry-run to preview changes without applying them.
# Run with --help for full usage.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_BASE="$HOME/.terminal-config-backup"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$BACKUP_BASE/$TIMESTAMP"
MANIFEST=""
CONFIG_DIR="$HOME/.modern-terminal"
ITERM_PROFILES_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
ZSHRC="$HOME/.zshrc"
SOURCE_LINE='[[ -f ~/.modern-terminal/init.zsh ]] && source ~/.modern-terminal/init.zsh'
SOURCE_COMMENT='# modern terminal config'

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# Flags
DRY_RUN=false
SKIP_BREW=false
SKIP_ZSH=false
SKIP_ITERM=false
SKIP_TMUX=false
SKIP_GIT=false
SKIP_PLUGINS=false
SKIP_ALIASES=false
SKIP_OPENCODE=false
SKIP_ITERM_AI=false
SKIP_BEDROCK=false

# =============================================================================
# Helpers
# =============================================================================

info()  { echo -e "${BLUE}ℹ${NC} $*"; }
ok()    { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC} $*"; }
err()   { echo -e "${RED}✗${NC} $*"; }
header(){ echo -e "\n${BOLD}${CYAN}$*${NC}"; echo -e "${DIM}$(printf '─%.0s' {1..60})${NC}"; }

log_action() {
  if [[ -n "$MANIFEST" ]]; then
    echo "$*" >> "$MANIFEST"
  fi
}

confirm() {
  local prompt="$1"
  if $DRY_RUN; then return 0; fi
  echo -en "${YELLOW}?${NC} $prompt ${DIM}[y/N]${NC} "
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

backup_file() {
  local file="$1"
  if [[ -f "$file" || -L "$file" ]]; then
    local rel="${file#"$HOME"/}"
    local dest="$BACKUP_DIR/$rel"
    if $DRY_RUN; then
      info "Would backup: $file → $dest"
      return
    fi
    mkdir -p "$(dirname "$dest")"
    cp -a "$file" "$dest"
    log_action "BACKUP $file $dest"
    ok "Backed up: ${DIM}$file${NC}"
  fi
}

# =============================================================================
# Usage
# =============================================================================

usage() {
  cat <<EOF
${BOLD}Modern Terminal Configuration - Installer${NC}

${BOLD}Usage:${NC}
  ./install.sh [options]

${BOLD}Options:${NC}
  --dry-run         Preview all changes without applying them
  --skip-brew       Skip Homebrew package installation
  --skip-zsh        Skip zsh configuration (plugins, aliases, fzf)
  --skip-iterm      Skip iTerm2 Dynamic Profile installation
  --skip-tmux       Skip tmux configuration
  --skip-git        Skip git/delta configuration
  --skip-plugins    Skip zsh plugin loading (use existing plugins)
  --skip-aliases    Skip modern CLI aliases (keep existing aliases)
  --skip-opencode   Skip OpenCode theme configuration
  --skip-iterm-ai   Skip iTerm2 AI plugin configuration
  --skip-bedrock    Skip AWS Bedrock SSO profile and auth script setup
  -h, --help        Show this help message

${BOLD}What it does:${NC}
  1. Installs CLI tools via Homebrew (Brewfile)
  2. Adds an iTerm2 Dynamic Profile (additive, doesn't replace Default)
  3. Symlinks zsh config to ~/.modern-terminal/
  4. Appends one source line to ~/.zshrc
  5. Installs tmux config and TPM plugins
  6. Configures git delta for better diffs

${BOLD}Safety:${NC}
  • Every modified file is backed up to ~/.terminal-config-backup/<timestamp>/
  • All actions are logged to a manifest for uninstall.sh
  • Original commands remain accessible (e.g., /bin/ls, /usr/bin/grep)
  • Run with --dry-run first to review changes

${BOLD}Uninstall:${NC}
  ./uninstall.sh              # Restore from latest backup
  ./uninstall.sh --remove-packages  # Also uninstall brew packages
EOF
  exit 0
}

# =============================================================================
# Parse Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)        DRY_RUN=true ;;
    --skip-brew)      SKIP_BREW=true ;;
    --skip-zsh)       SKIP_ZSH=true ;;
    --skip-iterm)     SKIP_ITERM=true ;;
    --skip-tmux)      SKIP_TMUX=true ;;
    --skip-git)       SKIP_GIT=true ;;
    --skip-plugins)   SKIP_PLUGINS=true ;;
    --skip-aliases)   SKIP_ALIASES=true ;;
    --skip-opencode)  SKIP_OPENCODE=true ;;
    --skip-iterm-ai)  SKIP_ITERM_AI=true ;;
    --skip-bedrock)   SKIP_BEDROCK=true ;;
    -h|--help)        usage ;;
    *) err "Unknown option: $1"; usage ;;
  esac
  shift
done

# =============================================================================
# Prerequisites
# =============================================================================

header "Checking prerequisites"

if [[ "$(uname)" != "Darwin" ]]; then
  err "This installer is designed for macOS only."
  exit 1
fi
ok "macOS detected"

if ! command -v brew &>/dev/null; then
  err "Homebrew is required. Install it from https://brew.sh"
  exit 1
fi
ok "Homebrew installed"

if [[ ! -d "/Applications/iTerm.app" ]] && [[ ! -d "$HOME/Applications/iTerm.app" ]]; then
  warn "iTerm2 not found. iTerm-specific features will still install but won't take effect until iTerm2 is installed."
fi

if [[ ! -f "$ZSHRC" ]]; then
  warn "No ~/.zshrc found. One will be created."
fi

# =============================================================================
# Conflict Detection
# =============================================================================

header "Scanning for conflicts"

CONFLICTS=()
CONFLICT_FILES=()
CONFLICT_ACTIONS=()

scan_file_for_pattern() {
  local file="$1" pattern="$2" label="$3" action="$4"
  if [[ -f "$file" ]]; then
    local matches
    matches=$(grep -n "$pattern" "$file" 2>/dev/null || true)
    if [[ -n "$matches" ]]; then
      while IFS= read -r match; do
        local line_num="${match%%:*}"
        CONFLICTS+=("$label")
        CONFLICT_FILES+=("$(basename "$file"):$line_num")
        CONFLICT_ACTIONS+=("$action")
      done <<< "$matches"
    fi
  fi
}

# Duplicate plugin loading
if ! $SKIP_ZSH && ! $SKIP_PLUGINS; then
  scan_file_for_pattern "$ZSHRC" "zsh-syntax-highlighting" "duplicate: zsh-syntax-highlighting" "comment out or use --skip-plugins"
  scan_file_for_pattern "$ZSHRC" "zsh-autosuggestions" "duplicate: zsh-autosuggestions" "comment out or use --skip-plugins"
  scan_file_for_pattern "$ZSHRC" "zsh-completions" "duplicate: zsh-completions" "comment out or use --skip-plugins"
fi

# Competing prompt themes
scan_file_for_pattern "$ZSHRC" "oh-my-zsh" "competing prompt: oh-my-zsh" "manual: remove oh-my-zsh theme"
scan_file_for_pattern "$ZSHRC" 'eval.*starship' "competing prompt: starship" "manual: remove starship init"
scan_file_for_pattern "$ZSHRC" "prompt pure" "competing prompt: pure" "manual: remove pure prompt"

# Alias collisions
if ! $SKIP_ZSH && ! $SKIP_ALIASES; then
  for cmd in ls cat grep find tree; do
    scan_file_for_pattern "$ZSHRC" "alias $cmd=" "alias collision: $cmd" "remove or use --skip-aliases"
  done
fi

# Duplicate compinit
if ! $SKIP_ZSH; then
  compinit_count=$(grep -c "compinit" "$ZSHRC" 2>/dev/null || echo "0")
  if [[ "$compinit_count" -gt 0 ]]; then
    CONFLICTS+=("duplicate compinit ($compinit_count calls)")
    CONFLICT_FILES+=(".zshrc")
    CONFLICT_ACTIONS+=("safe: our init.zsh skips if already loaded")
  fi
fi

# fzf keybinding conflicts
if ! $SKIP_ZSH; then
  scan_file_for_pattern "$ZSHRC" "fzf/shell" "duplicate: fzf keybindings" "comment out (we load them in fzf.zsh)"
  scan_file_for_pattern "$ZSHRC" "fzf.zsh" "duplicate: fzf config" "comment out (we load them in fzf.zsh)"
fi

# tmux conflicts
if ! $SKIP_TMUX && [[ -f "$HOME/.tmux.conf" ]]; then
  CONFLICTS+=("existing $HOME/.tmux.conf")
  CONFLICT_FILES+=("$HOME/.tmux.conf")
  CONFLICT_ACTIONS+=("backup + replace (original saved)")

  # Check for specific conflicts
  if grep -q "prefix" "$HOME/.tmux.conf" 2>/dev/null; then
    existing_prefix=$(grep "set.*prefix" "$HOME/.tmux.conf" 2>/dev/null | head -1 || true)
    if [[ -n "$existing_prefix" ]] && ! echo "$existing_prefix" | grep -q "C-a"; then
      CONFLICTS+=("tmux prefix key differs (ours: Ctrl+a)")
      CONFLICT_FILES+=("$HOME/.tmux.conf")
      CONFLICT_ACTIONS+=("info: will use Ctrl+a after install")
    fi
  fi

  if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    CONFLICTS+=("TPM already installed")
    CONFLICT_FILES+=("$HOME/.tmux/plugins/tpm")
    CONFLICT_ACTIONS+=("safe: will reuse existing TPM")
  fi
fi

# Print conflict report
if [[ ${#CONFLICTS[@]} -gt 0 ]]; then
  echo ""
  warn "Conflict Report"
  printf "${DIM}%-40s %-20s %s${NC}\n" "  CONFLICT" "FILE:LINE" "ACTION"
  echo -e "${DIM}$(printf '─%.0s' {1..80})${NC}"
  for i in "${!CONFLICTS[@]}"; do
    color="$YELLOW"
    if [[ "${CONFLICT_ACTIONS[$i]}" == safe* ]]; then
      color="$DIM"
    elif [[ "${CONFLICT_ACTIONS[$i]}" == manual* ]]; then
      color="$RED"
    fi
    printf "  ${color}%-38s${NC} %-20s %s\n" "${CONFLICTS[$i]}" "${CONFLICT_FILES[$i]}" "${CONFLICT_ACTIONS[$i]}"
  done
  echo -e "${DIM}$(printf '─%.0s' {1..80})${NC}"
  echo ""

  # Check for manual-resolution-required conflicts
  has_manual=false
  for action in "${CONFLICT_ACTIONS[@]}"; do
    if [[ "$action" == manual* ]]; then
      has_manual=true
      break
    fi
  done

  if $has_manual; then
    err "Some conflicts require manual resolution (marked 'manual:' above)."
    err "Please fix them in your ~/.zshrc before running the installer."
    if ! $DRY_RUN; then
      exit 1
    fi
  fi
else
  ok "No conflicts detected"
fi

if $DRY_RUN; then
  header "Dry run - no changes will be made"
fi

# =============================================================================
# Preview Plan
# =============================================================================

header "Installation Plan"

echo -e "  The following changes will be made:\n"
$SKIP_BREW   || echo -e "  ${GREEN}▸${NC} Install CLI tools via Homebrew (Brewfile)"
$SKIP_ITERM  || echo -e "  ${GREEN}▸${NC} Add iTerm2 Dynamic Profile: ${DIM}Dracula${NC}"
$SKIP_ZSH    || echo -e "  ${GREEN}▸${NC} Symlink zsh config: ${DIM}$CONFIG_DIR → $SCRIPT_DIR/config/zsh${NC}"
$SKIP_ZSH    || echo -e "  ${GREEN}▸${NC} Append source line to: ${DIM}$ZSHRC${NC}"
$SKIP_TMUX   || echo -e "  ${GREEN}▸${NC} Symlink tmux config: ${DIM}~/.tmux.conf → $SCRIPT_DIR/config/tmux/tmux.conf${NC}"
$SKIP_TMUX   || echo -e "  ${GREEN}▸${NC} Install TPM (Tmux Plugin Manager)"
$SKIP_GIT     || echo -e "  ${GREEN}▸${NC} Git delta config: ${DIM}~/.modern-terminal/git/delta.gitconfig${NC}"
$SKIP_BEDROCK || echo -e "  ${GREEN}▸${NC} AWS Bedrock: SSO profile + ~/bin/bedrock-auth"
echo -e "  ${GREEN}▸${NC} Set up Powerlevel10k prompt theme (Dracula)"
echo -e "  ${GREEN}▸${NC} Backups saved to: ${DIM}$BACKUP_DIR${NC}"
echo ""

if ! $DRY_RUN; then
  if ! confirm "Proceed with installation?"; then
    info "Installation cancelled."
    exit 0
  fi
fi

# =============================================================================
# Create Backup Directory
# =============================================================================

if ! $DRY_RUN; then
  mkdir -p "$BACKUP_DIR"
  MANIFEST="$BACKUP_DIR/manifest.log"
  echo "# Modern Terminal Install Manifest - $TIMESTAMP" > "$MANIFEST"
  {
    echo "# Script: $SCRIPT_DIR/install.sh"
    echo "# Flags: dry_run=$DRY_RUN skip_brew=$SKIP_BREW skip_zsh=$SKIP_ZSH skip_iterm=$SKIP_ITERM skip_tmux=$SKIP_TMUX skip_git=$SKIP_GIT"
    echo ""
  } >> "$MANIFEST"
fi

# =============================================================================
# 1. Homebrew Packages
# =============================================================================

if ! $SKIP_BREW; then
  header "Installing Homebrew packages"
  if $DRY_RUN; then
    info "Would run: brew bundle --file=$SCRIPT_DIR/Brewfile"
  else
    log_action "BREW_BUNDLE $SCRIPT_DIR/Brewfile"
    brew bundle --file="$SCRIPT_DIR/Brewfile" || {
      warn "Some packages may have failed. Continuing..."
    }
    ok "Homebrew packages installed"
  fi
fi

# =============================================================================
# 2. iTerm2 Dynamic Profile
# =============================================================================

if ! $SKIP_ITERM; then
  header "Installing iTerm2 Dynamic Profile"
  profile_dest="$ITERM_PROFILES_DIR/dracula.json"
  if $DRY_RUN; then
    info "Would copy: $SCRIPT_DIR/config/iterm2/dracula.json → $profile_dest"
  else
    backup_file "$profile_dest"
    mkdir -p "$ITERM_PROFILES_DIR"
    cp "$SCRIPT_DIR/config/iterm2/dracula.json" "$profile_dest"
    log_action "COPY $SCRIPT_DIR/config/iterm2/dracula.json $profile_dest"
    ok "Dynamic Profile installed (select 'Dracula' in iTerm2 → Profiles)"
  fi
fi

# =============================================================================
# 3. Zsh Configuration
# =============================================================================

if ! $SKIP_ZSH; then
  header "Installing zsh configuration"

  # Symlink config directory
  if $DRY_RUN; then
    info "Would symlink: $CONFIG_DIR → $SCRIPT_DIR/config/zsh"
  else
    backup_file "$CONFIG_DIR"
    if [[ -e "$CONFIG_DIR" ]] && [[ ! -L "$CONFIG_DIR" ]]; then
      mv "$CONFIG_DIR" "$BACKUP_DIR/modern-terminal-old"
      log_action "MOVE $CONFIG_DIR $BACKUP_DIR/modern-terminal-old"
    fi
    rm -f "$CONFIG_DIR"
    ln -sf "$SCRIPT_DIR/config/zsh" "$CONFIG_DIR"
    log_action "SYMLINK $CONFIG_DIR $SCRIPT_DIR/config/zsh"
    ok "Symlinked: $CONFIG_DIR"
  fi

  # Also symlink git config into the same dir for aliases.zsh to find
  if ! $SKIP_GIT; then
    git_link="$CONFIG_DIR/git"
    if $DRY_RUN; then
      info "Would symlink: $git_link → $SCRIPT_DIR/config/git"
    else
      rm -f "$git_link"
      ln -sf "$SCRIPT_DIR/config/git" "$git_link"
      log_action "SYMLINK $git_link $SCRIPT_DIR/config/git"
    fi
  fi

  # Clone fzf-tab into vendor directory
  fzf_tab_dir="$SCRIPT_DIR/vendor/fzf-tab"
  if [[ ! -d "$fzf_tab_dir" ]]; then
    if $DRY_RUN; then
      info "Would clone: fzf-tab → $fzf_tab_dir"
    else
      mkdir -p "$SCRIPT_DIR/vendor"
      git clone --depth 1 https://github.com/Aloxaf/fzf-tab.git "$fzf_tab_dir" 2>/dev/null || {
        warn "Could not clone fzf-tab. Tab completion will use default zsh."
      }
      log_action "CLONE fzf-tab $fzf_tab_dir"
    fi
  else
    ok "fzf-tab already present"
  fi

  # Download iTerm2 shell integration
  iterm_int="$HOME/.iterm2_shell_integration.zsh"
  if [[ ! -f "$iterm_int" ]]; then
    if $DRY_RUN; then
      info "Would download: iTerm2 shell integration → $iterm_int"
    else
      curl -fsSL https://iterm2.com/shell_integration/zsh -o "$iterm_int" 2>/dev/null || {
        warn "Could not download iTerm2 shell integration. Skipping."
      }
      log_action "DOWNLOAD iterm2_shell_integration $iterm_int"
      ok "Downloaded iTerm2 shell integration"
    fi
  else
    ok "iTerm2 shell integration already present"
  fi

  # Append source line to .zshrc
  if $DRY_RUN; then
    if grep -qF "$SOURCE_LINE" "$ZSHRC" 2>/dev/null; then
      ok "Source line already in .zshrc"
    else
      info "Would append to ~/.zshrc:"
      echo -e "    ${DIM}$SOURCE_COMMENT${NC}"
      echo -e "    ${DIM}$SOURCE_LINE${NC}"
    fi
  else
    backup_file "$ZSHRC"
    if grep -qF "$SOURCE_LINE" "$ZSHRC" 2>/dev/null; then
      ok "Source line already in .zshrc"
    else
      {
        echo ""
        echo "$SOURCE_COMMENT"
        echo "$SOURCE_LINE"
      } >> "$ZSHRC"
      log_action "APPEND $ZSHRC $SOURCE_LINE"
      ok "Appended source line to .zshrc"
    fi
  fi
fi

# =============================================================================
# 4. tmux Configuration
# =============================================================================

if ! $SKIP_TMUX; then
  header "Installing tmux configuration"

  tmux_conf="$HOME/.tmux.conf"
  if $DRY_RUN; then
    info "Would symlink: $tmux_conf → $SCRIPT_DIR/config/tmux/tmux.conf"
  else
    backup_file "$tmux_conf"
    rm -f "$tmux_conf"
    ln -sf "$SCRIPT_DIR/config/tmux/tmux.conf" "$tmux_conf"
    log_action "SYMLINK $tmux_conf $SCRIPT_DIR/config/tmux/tmux.conf"
    ok "Symlinked: ~/.tmux.conf"
  fi

  # Install TPM
  tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ ! -d "$tpm_dir" ]]; then
    if $DRY_RUN; then
      info "Would clone: TPM → $tpm_dir"
    else
      git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir" 2>/dev/null || {
        warn "Could not clone TPM. tmux plugins won't auto-install."
      }
      log_action "CLONE tpm $tpm_dir"
      ok "Installed TPM"
    fi
  else
    ok "TPM already installed"
  fi

  # Install TPM plugins (headless)
  if [[ -x "$tpm_dir/bin/install_plugins" ]]; then
    if $DRY_RUN; then
      info "Would install tmux plugins via TPM"
    else
      "$tpm_dir/bin/install_plugins" >/dev/null 2>&1 || {
        warn "Could not install tmux plugins. Run prefix + I inside tmux to install manually."
      }
      log_action "TPM_INSTALL_PLUGINS"
      ok "Installed tmux plugins"
    fi
  fi
fi

# =============================================================================
# 5. Git / Delta Configuration
# =============================================================================

if ! $SKIP_GIT; then
  header "Configuring git delta"

  delta_conf="$CONFIG_DIR/git/delta.gitconfig"
  if $DRY_RUN; then
    if git config --global --get include.path 2>/dev/null | grep -q "delta.gitconfig"; then
      ok "Git already includes delta config"
    else
      info "Would add to ~/.gitconfig: [include] path = $delta_conf"
    fi
  else
    if ! git config --global --get-all include.path 2>/dev/null | grep -q "delta.gitconfig"; then
      backup_file "$HOME/.gitconfig"
      git config --global --add include.path "$delta_conf"
      log_action "GITCONFIG include.path $delta_conf"
      ok "Added delta config to ~/.gitconfig"
    else
      ok "Git already includes delta config"
    fi
  fi
fi

# =============================================================================
# 6. Powerlevel10k Setup
# =============================================================================

header "Setting up Powerlevel10k"

  P10K_BREW_PREFIX="$(brew --prefix 2>/dev/null)"
  P10K_THEME="${P10K_BREW_PREFIX}/share/powerlevel10k/powerlevel10k.zsh-theme"

  if [[ ! -f "$P10K_THEME" ]]; then
    warn "Powerlevel10k not found at $P10K_THEME"
    warn "It should have been installed via Homebrew. Try: brew install powerlevel10k"
  else
    ok "Powerlevel10k installed"
    log_action "P10K_FOUND $P10K_THEME"

    P10K_CONFIG="$HOME/.p10k.zsh"
    P10K_DEFAULT="$SCRIPT_DIR/config/zsh/p10k-default.zsh"
    if [[ -f "$P10K_DEFAULT" ]]; then
      if $DRY_RUN; then
        if [[ -f "$P10K_CONFIG" ]]; then
          info "Would backup existing ~/.p10k.zsh and replace with repo Dracula default."
        else
          info "Would install Dracula p10k config from repo → ~/.p10k.zsh"
        fi
      else
        backup_file "$P10K_CONFIG"
        cp "$P10K_DEFAULT" "$P10K_CONFIG"
        log_action "COPY $P10K_DEFAULT $P10K_CONFIG"
        ok "Installed p10k config (Dracula): ~/.p10k.zsh"
        info "Customize later with: ${BOLD}p10k configure${NC}"
      fi
    else
      warn "Default p10k config not found at $P10K_DEFAULT"
      info "Run ${BOLD}p10k configure${NC} to set up your prompt style."
    fi
  fi

# =============================================================================
# 7. iTerm2 AI Plugin Configuration
# =============================================================================

if ! $SKIP_ITERM_AI; then
  header "Configuring iTerm2 AI plugin"

  if $DRY_RUN; then
    info "Would configure iTerm2 AI settings via defaults write"
    info "  Model: gpt-5.2, API: OpenAI Responses, all features enabled"
    info "  Note: API key and consent must be set manually in iTerm2 → Settings → General → AI"
  else
    # AI model and API settings
    defaults write com.googlecode.iterm2 AiModel -string "gpt-5.2"
    defaults write com.googlecode.iterm2 AitermURL -string "https://api.openai.com/v1/responses"
    defaults write com.googlecode.iterm2 AITermAPI -int 2
    defaults write com.googlecode.iterm2 AiMaxTokens -int 400000
    defaults write com.googlecode.iterm2 AiResponseMaxTokens -int 128000

    # Enable all AI features
    defaults write com.googlecode.iterm2 AIFeatureFunctionCalling -bool YES
    defaults write com.googlecode.iterm2 AIFeatureStreamingResponses -bool YES
    defaults write com.googlecode.iterm2 AIFeatureHostedCodeInterpeter -bool YES
    defaults write com.googlecode.iterm2 AIFeatureHostedFileSearch -bool YES
    defaults write com.googlecode.iterm2 AIFeatureHostedWebSearch -bool YES
    defaults write com.googlecode.iterm2 AIVectorStore -int 0

    log_action "DEFAULTS_WRITE com.googlecode.iterm2 AI settings"
    ok "Configured iTerm2 AI plugin settings"
    warn "API key and consent must be set manually: iTerm2 → Settings → General → AI"
  fi
fi

# =============================================================================
# 8. OpenCode Theme Configuration
# =============================================================================

if ! $SKIP_OPENCODE; then
  header "Configuring OpenCode theme (Dracula)"

  OC_CONFIG_DIR="$HOME/.config/opencode"
  OC_THEMES_DIR="$OC_CONFIG_DIR/themes"
  OC_THEME_SRC="$SCRIPT_DIR/config/opencode/themes/dracula.json"
  OC_THEME_DEST="$OC_THEMES_DIR/dracula.json"
  OC_TUI_SRC="$SCRIPT_DIR/config/opencode/tui.json"
  OC_TUI_DEST="$OC_CONFIG_DIR/tui.json"
  OC_OPENCODE_SRC="$SCRIPT_DIR/config/opencode/opencode.json"
  OC_OPENCODE_DEST="$OC_CONFIG_DIR/opencode.json"

  if $DRY_RUN; then
    info "Would create: $OC_THEMES_DIR"
    info "Would symlink: $OC_THEME_DEST → $OC_THEME_SRC"
    if [[ -f "$OC_TUI_DEST" ]]; then
      info "Would backup existing $OC_TUI_DEST and replace with Dracula tui.json"
    else
      info "Would install: $OC_TUI_DEST (theme: dracula)"
    fi
    if [[ ! -f "$OC_OPENCODE_DEST" ]]; then
      info "Would install: $OC_OPENCODE_DEST (base server config)"
    fi
  else
    mkdir -p "$OC_THEMES_DIR"
    log_action "MKDIR $OC_THEMES_DIR"

    backup_file "$OC_THEME_DEST"
    cp "$OC_THEME_SRC" "$OC_THEME_DEST"
    log_action "COPY $OC_THEME_DEST $OC_THEME_SRC"
    ok "Installed: ~/.config/opencode/themes/dracula.json"

    backup_file "$OC_TUI_DEST"
    cp "$OC_TUI_SRC" "$OC_TUI_DEST"
    log_action "COPY $OC_TUI_SRC $OC_TUI_DEST"
    ok "Installed OpenCode TUI config (theme: dracula): ~/.config/opencode/tui.json"

    if [[ ! -f "$OC_OPENCODE_DEST" ]]; then
      cp "$OC_OPENCODE_SRC" "$OC_OPENCODE_DEST"
      log_action "COPY $OC_OPENCODE_SRC $OC_OPENCODE_DEST"
      ok "Installed OpenCode server config: ~/.config/opencode/opencode.json"
    else
      ok "opencode.json already exists — skipping (add providers/models manually)"
    fi
  fi
fi

# =============================================================================
# 9. AWS Bedrock Setup
# =============================================================================

if ! $SKIP_BEDROCK; then
  header "Setting up AWS Bedrock (SSO + auth script)"

  AWS_CONFIG="$HOME/.aws/config"
  SSO_SESSION_NAME="my-sso"
  BEDROCK_PROFILE="WFS-Architects-RD"
  BEDROCK_REGION="us-east-1"
  BEDROCK_SCRIPT_SRC="$SCRIPT_DIR/scripts/bedrock-auth.sh"
  BEDROCK_SCRIPT_DEST="$HOME/bin/bedrock-auth"

  if $DRY_RUN; then
    info "Would create ~/bin/ if missing"
    info "Would install: $BEDROCK_SCRIPT_DEST"
    if ! grep -q "\[sso-session ${SSO_SESSION_NAME}\]" "$AWS_CONFIG" 2>/dev/null; then
      info "Would add [sso-session ${SSO_SESSION_NAME}] to ~/.aws/config"
    else
      ok "SSO session '${SSO_SESSION_NAME}' already in ~/.aws/config"
    fi
    if ! grep -q "\[profile ${BEDROCK_PROFILE}\]" "$AWS_CONFIG" 2>/dev/null; then
      info "Would add [profile ${BEDROCK_PROFILE}] to ~/.aws/config"
    else
      ok "AWS profile '${BEDROCK_PROFILE}' already in ~/.aws/config"
    fi
    info "Run: bedrock-login  (after install, to authenticate via Microsoft Entra ID)"
  else
    # Install bedrock-auth script to ~/bin/
    mkdir -p "$HOME/bin"
    cp "$BEDROCK_SCRIPT_SRC" "$BEDROCK_SCRIPT_DEST"
    chmod +x "$BEDROCK_SCRIPT_DEST"
    log_action "COPY $BEDROCK_SCRIPT_SRC $BEDROCK_SCRIPT_DEST"
    ok "Installed: ~/bin/bedrock-auth"

    # Bootstrap ~/.aws/config if SSO session entry is missing
    mkdir -p "$HOME/.aws"
    if ! grep -q "\[sso-session ${SSO_SESSION_NAME}\]" "$AWS_CONFIG" 2>/dev/null; then
      cat >> "$AWS_CONFIG" <<AWSEOF

[sso-session ${SSO_SESSION_NAME}]
sso_start_url = https://wfscorp.awsapps.com/start
sso_region = ${BEDROCK_REGION}
sso_registration_scopes = sso:account:access
AWSEOF
      log_action "AWSCONFIG sso-session ${SSO_SESSION_NAME}"
      ok "Added SSO session '${SSO_SESSION_NAME}' to ~/.aws/config"
    else
      ok "SSO session '${SSO_SESSION_NAME}' already configured"
    fi

    # Bootstrap AWS profile entry if missing
    if ! grep -q "\[profile ${BEDROCK_PROFILE}\]" "$AWS_CONFIG" 2>/dev/null; then
      cat >> "$AWS_CONFIG" <<AWSEOF

[profile ${BEDROCK_PROFILE}]
sso_session = ${SSO_SESSION_NAME}
sso_account_id = 711387094947
sso_role_name = WFSPowerUserAccess
region = ${BEDROCK_REGION}
AWSEOF
      log_action "AWSCONFIG profile ${BEDROCK_PROFILE}"
      ok "Added AWS profile '${BEDROCK_PROFILE}' to ~/.aws/config"
    else
      ok "AWS profile '${BEDROCK_PROFILE}' already configured"
    fi

    warn "Run ${BOLD}bedrock-login${NC} to authenticate via Microsoft Entra ID SSO"
  fi
fi

# =============================================================================
# Summary
# =============================================================================

header "Installation complete"

if $DRY_RUN; then
  info "This was a dry run. No changes were made."
  info "Run without --dry-run to apply changes."
else
  echo -e "
  ${GREEN}${BOLD}What's next:${NC}

  ${BOLD}1.${NC} Restart your terminal (or run: ${DIM}source ~/.zshrc${NC})
  ${BOLD}2.${NC} Authenticate with AWS Bedrock: ${DIM}bedrock-login${NC}
     (opens browser for Microsoft Entra ID SSO)
  ${BOLD}3.${NC} In iTerm2, switch to the ${DIM}Dracula${NC} profile:
     Settings → Profiles → select 'Dracula' → set as Default
  ${BOLD}4.${NC} Try the AI workspace: ${DIM}ai-workspace${NC}

  ${BOLD}Backups:${NC} $BACKUP_DIR
  ${BOLD}Manifest:${NC} $MANIFEST
  ${BOLD}Uninstall:${NC} $SCRIPT_DIR/uninstall.sh
"
fi

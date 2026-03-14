# Architecture

## Design Principles

1. **Non-destructive** — every changed file is backed up before being touched
2. **Reversible** — `uninstall.sh` restores all backups and removes only what was added
3. **Transparent** — install prints a plan and asks for confirmation
4. **Modular** — each feature can be skipped independently

## Install Flow

```mermaid
flowchart TD
    A[./install.sh] --> B{Parse flags}
    B --> C[Check prerequisites<br/>macOS, Homebrew, iTerm2]
    C --> D[Scan for conflicts]
    D --> E{Conflicts found?}
    E -->|Manual required| F[Print report, exit]
    E -->|Safe/none| G[Print installation plan]
    G --> H{User confirms?}
    H -->|No| I[Exit]
    H -->|Yes| J[Create backup dir<br/>~/.terminal-config-backup/timestamp/]
    J --> K[Brew bundle install]
    K --> L[Copy iTerm2 Dynamic Profile]
    L --> M[Symlink ~/.modern-terminal → config/zsh/]
    M --> N[Clone fzf-tab to vendor/]
    N --> O[Download iTerm2 shell integration]
    O --> P[Append source line to ~/.zshrc]
    P --> Q[Symlink ~/.tmux.conf]
    Q --> R[Install TPM]
    R --> S[Add delta include to ~/.gitconfig]
    S --> T[Verify Powerlevel10k<br/>detect existing ~/.p10k.zsh]
    T --> U[Bootstrap AWS Bedrock<br/>~/.aws/config + ~/bin/bedrock-auth<br/>~/.config/opencode/opencode.json]
    U --> V[Print summary]
```

## Uninstall Flow

```mermaid
flowchart TD
    A[./uninstall.sh] --> B[Find latest backup]
    B --> C[Read manifest.log]
    C --> D[Print uninstall plan]
    D --> E{User confirms?}
    E -->|No| F[Exit]
    E -->|Yes| G[Remove source line from .zshrc]
    G --> H[Remove ~/.modern-terminal symlink]
    H --> I[Remove iTerm2 Dynamic Profile]
    I --> J[Remove ~/.tmux.conf symlink]
    J --> K[Remove delta include from .gitconfig]
    K --> L[Restore all backed-up files]
    L --> M{--remove-packages?}
    M -->|Yes| N[Uninstall brew packages]
    M -->|No| O[Print summary]
    N --> O
```

## Zsh Sourcing Chain

```mermaid
flowchart LR
    A["~/.zshrc"] -->|"existing config<br/>(p10k, nvm, etc.)"| B["User's setup"]
    A -->|"source line<br/>(appended)"| C["~/.modern-terminal/init.zsh"]
    C --> D["plugins.zsh<br/>compinit, fzf-tab,<br/>autosuggestions,<br/>syntax-highlighting"]
    C --> E["fzf.zsh<br/>keybindings,<br/>theme colors"]
    C --> F["aliases.zsh<br/>eza, bat, fd,<br/>rg, zoxide"]
    C --> G0["init.zsh sources p10k<br/>(if not already loaded)"]
    G0 --> G["p10k-overlay.zsh<br/>transient prompt,<br/>color overrides"]
    C --> H["tmux.zsh<br/>aliases,<br/>ai-workspace"]
    C --> J["aws.zsh<br/>AWS_PROFILE,<br/>bedrock aliases"]
    C --> I["iterm2-integration.zsh<br/>shell marks"]
```

## tmux AI Workspace Layout

```mermaid
graph TB
    subgraph session["tmux session: ai-dev"]
        subgraph left["Left column"]
            A["Pane 0 (70%)<br/>coding / git"]
            B["Pane 1 (25%)<br/>test runner / logs"]
        end
        subgraph right["Right column"]
            C["Pane 2 (30%)<br/>opencode AI TUI"]
        end
    end
```

## File System Layout

```
~/.zshrc                          ← one line appended (source ~/.modern-terminal/init.zsh)
~/.modern-terminal/               ← symlink → repo/config/zsh/
~/.tmux.conf                      ← symlink → repo/config/tmux/tmux.conf
~/.tmux/plugins/tpm/              ← TPM (cloned at install time)
~/.gitconfig                      ← [include] path added for delta
~/.iterm2_shell_integration.zsh   ← downloaded at install time
~/Library/Application Support/iTerm2/DynamicProfiles/dracula.json
~/bin/bedrock-auth                ← AWS SSO auth helper (copied from scripts/bedrock-auth.sh)
~/.aws/config                     ← WFS-Architects-RD profile + my-sso session (appended by installer)
~/.config/opencode/opencode.json  ← OpenCode config (amazon-bedrock provider, us-east-1)

~/.terminal-config-backup/
  └── 20240101_120000/
      ├── manifest.log            ← action log for uninstall
      ├── .zshrc                  ← original zshrc
      ├── .tmux.conf              ← original tmux config (if any)
      └── .gitconfig              ← original gitconfig
```

## Conflict Detection

The installer scans `~/.zshrc` before making changes and reports:

- **Duplicate plugins** — loading the same plugin twice causes slowdowns
- **Competing prompts** — multiple prompt themes clobber each other
- **Alias collisions** — existing aliases for ls, cat, cd, etc.
- **Duplicate compinit** — multiple calls are expensive; ours skips if already loaded
- **tmux conflicts** — different prefix keys or existing TPM installs
- **fzf conflicts** — duplicate keybinding sources

Each conflict is classified as:
- `safe:` — handled automatically, no action needed
- `comment out or use --skip-*` — installer can work around it
- `manual:` — user must fix before installing (blocks install)

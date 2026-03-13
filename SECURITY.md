# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| latest  | Yes       |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly:

1. **Do not** open a public issue
2. Email the maintainer or use GitHub's [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-managing-vulnerabilities/privately-reporting-a-security-vulnerability)
3. Include steps to reproduce the vulnerability
4. Allow reasonable time for a fix before public disclosure

## Scope

This project runs shell scripts that modify your local configuration. Security concerns include:

- **Install/uninstall scripts**: These modify dotfiles and install Homebrew packages. Always review scripts before running them.
- **Third-party dependencies**: Managed via Homebrew. Run `brew audit` to check package integrity.
- **Tmux Plugin Manager (TPM)**: Clones plugins from GitHub. Verify plugin sources before use.

## Best Practices

- Always use `--dry-run` before installing to preview changes
- Review the `install.sh` source code before running
- Keep dependencies updated (Renovate bot helps with GitHub Actions)

# Repository Structure

## Source Layout

```
dotfiles/
├── home/                    # Dotfile templates (managed by Chezmoi)
│   ├── .config/             # XDG_CONFIG_HOME files
│   │   ├── zsh/
│   │   ├── nvim/
│   │   ├── tmux/
│   │   └── git/
│   ├── dot_gitconfig.tmpl   # Becomes ~/.gitconfig
│   └── .profile.tmpl        # Becomes ~/.profile
├── tools/                   # Bootstrap & management scripts
│   ├── bootstrap.sh         # Main entry point
│   ├── os_installers/       # OS-specific package installers
│   └── os_setup/            # OS-specific configurations
├── scripts/                 # User utilities
│   ├── backup/
│   └── custom/
├── tests/                   # Automated tests (Bats, Pester)
└── .github/workflows/       # CI configuration
```

## Applied Structure (Your Machine)

| XDG Variable | Default Location | Purpose |
|--------------|------------------|---------|
| `XDG_CONFIG_HOME` | `~/.config` | App configurations |
| `XDG_DATA_HOME` | `~/.local/share` | App data (Zsh history, NVM, SDKMAN) |
| `XDG_CACHE_HOME` | `~/.cache` | Cache files |
| `XDG_STATE_HOME` | `~/.local/state` | State files |
| `XDG_BIN_HOME` | `~/.local/bin` | User binaries |

Chezmoi stores its data in:
- **Source**: `~/.local/share/chezmoi`
- **Config**: `~/.config/chezmoi/chezmoi.toml`

## Key Scripts

| Script | Purpose |
|--------|---------|
| `tools/bootstrap.sh` | Main setup entry point |
| `tools/xdg_setup.sh` | Sets XDG environment variables |
| `tools/install_global_tools.sh` | Installs npm/pip/dotnet tools |
| `tools/install_vscode_extensions.sh` | Installs VS Code extensions |

## Troubleshooting

Common Chezmoi commands:
```bash
chezmoi doctor   # Check setup
chezmoi diff     # Show pending changes
chezmoi apply    # Apply changes
chezmoi update   # Pull and apply from remote
```

See [Chezmoi documentation](https://www.chezmoi.io/docs/) for more help.

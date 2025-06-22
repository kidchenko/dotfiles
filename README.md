# @kidchenko's Dotfiles (v2 - XDG & Chezmoi Edition)

This repository contains my personal dotfiles, managed using [Chezmoi](https://chezmoi.io/) for a robust, cross-platform (macOS and Linux) setup. This version focuses on adhering to the XDG Base Directory Specification for a cleaner home directory.

## Features

*   **XDG Base Directory Specification**: Configurations, data, and cache files are stored in standard XDG locations (`~/.config`, `~/.local/share`, `~/.cache`).
*   **Managed by Chezmoi**: Dotfiles are treated as templates, allowing for dynamic configuration and management across multiple machines.
*   **Automated Tool Installation**:
    *   Global CLI tools (npm, pip, dotnet) are managed via a configuration file (`~/.config/dotfiles/config.yaml`).
    *   VS Code extensions are managed via a list file (`~/.config/dotfiles/vscode-extensions.txt`).
*   **Cross-Platform**: Designed to work on macOS and Linux.
*   **Idempotent Bootstrap**: The main bootstrap script can be run multiple times safely.
*   **Verbose Output & Dry-Run Mode**: For better control and understanding during setup.
*   **Customizable Zsh Environment**: Includes aliases, functions, and Oh My Zsh integration, all XDG-aware.
*   **Curated Configurations**: For Git, Neovim (from Vim), Tmux, and more.

## Prerequisites

Before running the bootstrap script, ensure you have the following installed:

*   **Git**: For cloning the repository and for Chezmoi's operations.
*   **curl** or **wget**: For downloading Chezmoi if it's not already installed.
*   **(Optional but Recommended)** A Nerd Font for your terminal to correctly display icons and symbols used in some prompts/themes (e.g., Hack Nerd Font, FiraCode Nerd Font).

The bootstrap script will attempt to install `yq` (YAML processor) if it's missing and you have a common package manager (Homebrew, apt, dnf, etc.) configured with `sudo` access if required. `yq` is used for processing the global tools configuration.

## Installation / Bootstrap

To set up your environment using these dotfiles, run the following command in your terminal:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/v2/tools/bootstrap.sh)"
```
*(Note: Ensure you are using the correct branch name, e.g., `v2` or `main`, in the URL if it differs from `master` or the default branch.)*

Alternatively, you can clone this repository manually and then run the bootstrap script:
```bash
git clone https://github.com/kidchenko/dotfiles.git ~/dotfiles_source # Or any other location
cd ~/dotfiles_source
bash tools/bootstrap.sh
>>>>>>> 8236eef (feat: Integrate Chezmoi, XDG, and tool/extension automation)
```
*Note: The default branch might be `master` or `main`. Adjust URL if necessary.*

### Bootstrap Script Options

The `bootstrap.sh` script accepts the following optional flags:

*   `--verbose`: Enable verbose output for the bootstrap process and sub-scripts.
*   `--dry-run`: Simulate installations and changes without modifying your system. Useful for seeing what the script will do.
*   `--force-chezmoi-init`: Forces `chezmoi init` even if Chezmoi appears to be already initialized. Useful for resetting the Chezmoi source.
*   `--repo <URL>`: Specify a different Git repository URL for your dotfiles if you've forked this repo.

Example:
```bash
bash tools/bootstrap.sh --verbose --dry-run
```

## Structure Overview (XDG + Chezmoi)

*   **Chezmoi Source Directory**: `~/.local/share/chezmoi` (this is where your dotfiles Git repository will be cloned by Chezmoi).
*   **Chezmoi Config File**: `~/.config/chezmoi/chezmoi.toml`.
*   **Dotfile Templates**: Located within the `home/` directory in this repository (e.g., `home/.config/zsh/.zshrc.tmpl`). Chezmoi processes these templates and creates the actual configuration files in your home directory (e.g., `~/.config/zsh/.zshrc`).
*   **XDG Directories Used**:
    *   `$XDG_CONFIG_HOME` (defaults to `~/.config`): For configuration files (e.g., `nvim`, `tmux`, `zsh`, `git/ignore`).
    *   `$XDG_DATA_HOME` (defaults to `~/.local/share`): For user data files (e.g., `nvim/undo`, `zsh/history` (via `$HISTFILE`), `nvm`, `sdkman`).
    *   `$XDG_CACHE_HOME` (defaults to `~/.cache`): For cached data (e.g., `nvim/shada`, `zsh/completions`).
    *   `$XDG_STATE_HOME` (defaults to `~/.local/state`): For state files (e.g., history logs if not in data).
    *   `$XDG_BIN_HOME` (defaults to `~/.local/bin`): For user-installed executables (added to `PATH`).

## Customization

### 1. Fork this Repository

It's highly recommended to fork this repository to your own GitHub account so you can customize it freely. Update the `DOTFILES_REPO_URL` in `tools/bootstrap.sh` or use the `--repo` flag during the first run.

### 2. Modifying Dotfiles

*   Edit the template files in your forked repository (e.g., `home/.config/nvim/init.vim.tmpl`).
*   After making changes, commit and push them to your Git repository.
*   Run `chezmoi apply` on any machine to apply the updates. You can add `chezmoi apply` to your shell's startup (e.g., `.zlogin`) or run it periodically.

### 3. Managing Global Tools

*   Edit `~/.config/dotfiles/config.yaml` (this file is created by Chezmoi from `home/.config/dotfiles/config.yaml.tmpl`).
*   Add or remove tools under the `npm`, `pip`, or `dotnet` sections.
*   Run `bash <path_to_your_dotfiles_repo>/tools/install_global_tools.sh` or re-run the main `tools/bootstrap.sh` script.

Example snippet from `config.yaml`:
```yaml
global_tools:
  npm:
    - http-server
    - eslint
  pip:
    - black
    - flake8
  dotnet:
    - dotnet-ef
```

### 4. Managing VS Code Extensions

*   Edit `~/.config/dotfiles/vscode-extensions.txt` (this file is created by Chezmoi from `home/.config/dotfiles/vscode-extensions.txt.tmpl`).
*   Add or remove extension IDs (one per line). Comments start with `#`.
*   Run `bash <path_to_your_dotfiles_repo>/tools/install_vscode_extensions.sh` or re-run the main `tools/bootstrap.sh` script.

### 5. Machine-Specific Configurations (Chezmoi Templating)

Chezmoi uses Go templating. You can make parts of your dotfiles conditional based on hostname, OS, or custom data.

*   **Data File**: Create a `.chezmoidata.yaml` (or `.json`/`.toml`) in the root of your dotfiles repository (next to `home/`).
    Example `.chezmoidata.yaml`:
    ```yaml
    email: "your_email@example.com"
    name: "Your Name"
    is_work_machine: false
    # Add other variables you want to use in templates
    ```
*   **Use in Templates**:
    ```gotemplate
    # In home/.gitconfig.tmpl
    [user]
      email = {{ .email | default "fallback@example.com" }}
      name = {{ .name | default "Fallback Name" }}

    {{ if .is_work_machine }}
    # Work-specific git config
    [includeIf "gitdir:~/work/"]
      path = .gitconfig-work
    {{ end }}
    ```
    The `config.yaml.tmpl` and `vscode-extensions.txt.tmpl` already include examples of conditional sections using `{{ if .is_work_machine }}`.

## Key Scripts

*   `tools/bootstrap.sh`: Main entry point for setting up the dotfiles.
*   `tools/run_once_install-chezmoi.sh`: Installs Chezmoi.
*   `tools/xdg_setup.sh`: Sets XDG environment variables for the current session.
*   `tools/install_global_tools.sh`: Installs global CLI tools.
*   `tools/install_vscode_extensions.sh`: Installs VS Code extensions.

## Troubleshooting

*   **Chezmoi**: Refer to the [official Chezmoi documentation](https://www.chezmoi.io/docs/). Common commands:
    *   `chezmoi doctor`: Checks your setup.
    *   `chezmoi edit <path_to_dotfile>`: Edit a dotfile managed by Chezmoi.
    *   `chezmoi apply`: Apply changes from your source repo.
    *   `chezmoi update`: Pulls changes from your Git remote and applies them.
    *   `chezmoi diff`: Shows differences between your target files and what Chezmoi would apply.
*   **Permissions**: Ensure scripts in the `tools/` directory are executable. The bootstrap script attempts to handle this.
*   **PATH issues**: If commands like `chezmoi`, `npm`, `pip`, `dotnet`, or newly installed tools are not found after running the bootstrap, you might need to start a new shell session or manually ensure their installation directories are in your `PATH`. The XDG setup aims to add `~/.local/bin` to `PATH`.

---

Built with ❤️ by @kidchenko. Adapted for XDG and enhanced automation.
Original v1 branch/README can be found [here](<link to old branch if it exists or remove this line>).

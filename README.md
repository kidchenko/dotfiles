# @kidchenko's Dotfiles v2: Powered by Chezmoi

🔧💻 My personal `.dotfiles` for macOS, Linux, and Windows, now supercharged with `chezmoi` for robust management and customization. This setup includes configurations for `zsh`, `PowerShell`, `git`, `vim`, and more, all managed intelligently.

[![CI](https://github.com/kidchenko/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/kidchenko/dotfiles/actions/workflows/ci.yml)

## Overview

These dotfiles aim to provide a consistent and personalized development environment across multiple operating systems. By leveraging `chezmoi`, we gain:

*   **Declarative configuration:** Define the desired state of your dotfiles.
*   **Cross-platform compatibility:** Manage files for macOS, Linux, and Windows from a single source.
*   **Templating:** Customize files based on OS or other conditions (though not heavily used in this version yet, `chezmoi` supports it).
*   **Security:** `chezmoi` can manage secrets (not used in this public version).

This revamped setup uses a central `config.yaml` to control various aspects, from software installation to feature enablement and custom hooks.

## Features

*   **Chezmoi Integration:** Robust dotfile management using `chezmoi`.
*   **Centralized Configuration:** Single `config.yaml` for easy customization of settings, features, and installations.
*   **OS Detection:** Scripts adapt behavior for macOS, Linux, and Windows.
*   **Modular Installation:** Software and PowerShell modules are installed via dedicated, idempotent functions.
*   **Feature Flags:** Easily enable or disable sets of features (e.g., Oh My Posh, specific tools) via `config.yaml`.
*   **Interactive Prompts:** Optional prompts for installations, controllable via a feature flag.
*   **Post-Install Hooks:** Run custom scripts or commands after the main setup.
*   **Idempotent Scripts:** Setup scripts can be run multiple times without causing issues.
*   **Improved Logging:** Consistent logging with timestamps and levels in setup scripts.
*   **Automated Testing:** CI pipeline using Bats-core (Bash) and Pester (PowerShell) to ensure reliability.

## Prerequisites

*   **Git:** Required for cloning this repository and for `chezmoi`'s operations.
*   **Operating System Specifics:**
    *   **macOS:** Homebrew is recommended for installing some dependencies. The install script can install `chezmoi` and `yq` via Homebrew if not present.
    *   **Linux:** A package manager like `apt-get` (Debian/Ubuntu) or `dnf` (Fedora) is expected for installing dependencies. `curl` or `wget` is needed for some installers. The install script can install `chezmoi` and `yq`.
    *   **Windows:** Chocolatey is recommended for installing some dependencies. The install script can install `chezmoi` via Chocolatey if not present. PowerShell 5.1 or higher.
*   **Shells:**
    *   **macOS/Linux:** `zsh` is recommended (though `bash` is the primary target for `setup.sh`). If you use `zsh`, consider Oh My Zsh.
    *   **Windows:** PowerShell.

## Installation

The one-liner commands will download an installer script (`tools/install.sh` for Bash, `tools/install.ps1` for PowerShell). This script will then:
1.  Install `chezmoi` if not already present (using Homebrew on macOS, a script on Linux, Chocolatey on Windows).
2.  Initialize `chezmoi` with this dotfiles repository.
3.  Run the main setup scripts (`setup.sh` or `setup.ps1`).
4.  These setup scripts read `config.yaml` to customize the setup, install software, and apply dotfiles via `chezmoi apply`.

### macOS / Linux (using Bash/Zsh)

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/install.sh)"
```
*Note: The default branch might be `master` or `main`. Adjust URL if necessary.*

### Windows (using PowerShell)

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/kidchenko/dotfiles/main/tools/install.ps1'))
```
*Note: The default branch might be `master` or `main`. Adjust URL if necessary.*

After installation, restart your terminal or source your shell profile (`~/.zshrc`, `~/.bashrc`, or PowerShell `$PROFILE`) for all changes to take effect.

## Configuration (`config.yaml`)

The heart of this dotfiles setup is the `config.yaml` file located in the root of the repository. It allows you to customize various aspects of your environment.

```yaml
# config.yaml (example structure)
general:
  username: "your_username" # Used for informational purposes or by hooks

tools:
  git:
    name: "Your Name"      # For global .gitconfig
    email: "your@email.com" # For global .gitconfig

feature_flags:
  withOhMyPosh: true             # Install and set up Oh My Posh
  installCoreSoftware: true      # Install core software like Git, Brave Browser
  installDevelopmentTools: true  # Placeholder for future dev tools
  installPowerShellModules: true # Install common PowerShell modules (Windows only)
  setupGitAliases: true          # Placeholder for Git alias setup via chezmoi/script
  interactivePrompts: false      # Set to true to be prompted before certain installations

post_install_hooks:
  enabled: true # Master switch for all post-install hooks
  scripts:
    - run_on: [linux, macos]
      script: "./custom_scripts/my_bash_hook.sh"
      description: "Example Bash hook for Linux/macOS."
    - run_on: [windows]
      command: "Write-Host 'Example Windows command hook.'"
      description: "Example Windows command hook."
```

### `general`
*   `username`: Currently informational. Could be used by custom scripts or `chezmoi` templates in the future.

### `tools.git`
*   `name`: Sets your global `user.name` in `.gitconfig`.
*   `email`: Sets your global `user.email` in `.gitconfig`.

### `feature_flags`
These boolean flags control which parts of the setup are executed:
*   `withOhMyPosh`: If true, attempts to install Oh My Posh for your shell.
*   `installCoreSoftware`: If true, installs essential software like Git (if not present) and Brave Browser.
*   `installDevelopmentTools`: A general flag that can be used to control the installation of a suite of development tools (currently a placeholder for further extension).
*   `installPowerShellModules`: If true (and on Windows), installs useful PowerShell modules like `posh-git`, `Terminal-Icons`, etc.
*   `setupGitAliases`: Placeholder for managing Git aliases, potentially through a dedicated script or by adding a Git aliases file to `chezmoi`.
*   `interactivePrompts`:
    *   If `false` (default): The scripts will run non-interactively, assuming default 'yes' for most operations where a choice might be offered (e.g., installing a specific application).
    *   If `true`: For certain operations (like installing Brave or Oh My Posh), you will be prompted for confirmation before proceeding.

### `post_install_hooks`
This section allows you to run custom scripts or commands after the main setup and `chezmoi apply` have completed.
*   `enabled`: A master switch. If `false`, no hooks will be run.
*   `scripts`: A list of hook definitions. Each item can have:
    *   `run_on`: A list of OS identifiers (e.g., `linux`, `macos`, `windows`) for which this hook should run. The script uses `get_os_type` (Bash) or `Get-OSType` (PowerShell) to determine the current OS.
    *   `script`: (Optional) Path to a script file to execute. Paths are typically relative to the dotfiles repository root (e.g., `./custom_scripts/my_script.sh`). The script will be executed from the dotfiles directory.
    *   `command`: (Optional) A direct command string to execute.
    *   `description`: A brief description of what the hook does, for logging purposes.

## Core Tooling: `chezmoi`

This setup uses `chezmoi` to manage your dotfiles. `chezmoi` initializes a local source directory (usually `~/.local/share/chezmoi`) where it stores your dotfiles. It then creates symlinks (or copies, depending on configuration) from this source to their target locations (e.g., `~/.zshrc`).

**Key `chezmoi` commands:**

*   `chezmoi add <file_path>`: Adds a new file to your `chezmoi` source directory.
    *   Example: `chezmoi add ~/.gitconfig`
*   `chezmoi apply`: Applies any pending changes from your `chezmoi` source directory to your target files. This is run automatically by the setup scripts.
*   `chezmoi edit <file_path>`: Opens a target file (e.g., `~/.zshrc`) in your editor. When you save, `chezmoi` updates its source directory.
*   `chezmoi update`: Pulls the latest changes from your dotfiles repository into `chezmoi`'s source directory and applies them.
*   `chezmoi status`: Shows files that have been modified or are managed by `chezmoi`.
*   `chezmoi forget <file_path>`: Stops `chezmoi` from managing a file.
*   `chezmoi diff`: Shows differences between your target files and the `chezmoi` source state.

For more detailed information, refer to the [official chezmoi documentation](https://www.chezmoi.io/docs/).

## Usage After Initial Setup

*   **Applying local changes:** If you manually edit a file in `~/.local/share/chezmoi` or want to ensure your system reflects the `chezmoi` source state, run:
    ```bash
    chezmoi apply
    ```
*   **Pulling updates from your Git repo:**
    ```bash
    chezmoi update
    ```
    This is often configured to run automatically by some `chezmoi` setups, but you can run it manually.
*   **Editing managed files:**
    ```bash
    chezmoi edit ~/.zshrc
    ```

## Extending Your Setup

### Adding New Dotfiles
1.  Create or modify the file in its target location (e.g., `~/.config/mytool/config.toml`).
2.  Run `chezmoi add ~/.config/mytool/config.toml`.
3.  Commit the changes in your dotfiles repository (`~/.kidchenko/dotfiles` or where your `chezmoi` source is version-controlled).

### Customizing Installations
*   **Modify `config.yaml`**: Toggle `feature_flags` or add/remove items from software installation lists (if the scripts are designed to read such lists, which is a potential future enhancement).
*   **Edit `setup.sh` or `setup.ps1`**:
    *   Add new installation functions for software not covered.
    *   Modify existing installation functions (e.g., to change package manager options or versions).
    *   Remember to maintain idempotency.

### Adding Custom Hooks
1.  Create your hook script (e.g., in `custom_scripts/`).
2.  Add a new entry to the `post_install_hooks.scripts` list in `config.yaml`, specifying `run_on`, `script` or `command`, and `description`.

## Fonts

*   **macOS/Linux:** [Hack Nerd Font](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/Hack) is recommended for terminal icons and a pleasant coding experience.
*   **Windows:** [Delugia Nerd Font](https://github.com/adam7/delugia-code) (a version of Consolas patched with Nerd Font icons) is recommended.

Font installation is typically manual or handled by your terminal emulator's settings. The setup scripts do not currently install fonts automatically.

## Aliases & Shell Customizations
Many aliases and shell functions are defined within the dotfiles themselves (e.g., in `.zshrc`, `.aliases`, PowerShell profile files). Explore these files after installation to see available shortcuts.

## Testing
This repository uses Bats-core for Bash testing and Pester for PowerShell testing.

### Running Bash Tests (Linux/macOS)
1.  **Prerequisites:**
    *   Ensure Bats-core is installed (e.g., `brew install bats-core` or `sudo apt-get install bats`).
    *   Ensure `yq` is installed (e.g., `brew install yq` or `sudo apt-get install yq`).
2.  **From the repository root:**
    ```bash
    # If Bats is in your PATH
    bats tests/bash/*.bats
    # Or, if using the CI Bats installation path:
    # /usr/local/lib/bats-core/bin/bats tests/bash/*.bats (path may vary)
    ```

### Running PowerShell Tests (Windows)
1.  **Prerequisites:**
    *   Ensure Pester is installed: `Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck`
    *   Ensure `powershell-yaml` module is installed: `Install-Module powershell-yaml -Scope CurrentUser -Force -SkipPublisherCheck`
2.  **From the repository root (in PowerShell):**
    ```powershell
    Invoke-Pester -Script @{Path = "./tests/powershell/*.Tests.ps1"} -OutputFormat NUnitXML -OutputFile Test-Pester.xml
    ```

## License
This project is licensed under the MIT License. See the `LICENSE` file for details (though a `LICENSE` file wasn't explicitly created in previous steps, it's standard to add one for MIT).

---
**Built with ❤️ by @kidchenko**

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Brave browser extensions management (`tools/install-brave-extensions.sh`)
- Windows support documentation in README and CLAUDE.md
- CHANGELOG.md for tracking changes
- SECURITY.md for security policy
- CONTRIBUTING.md for contributor guidelines

### Changed
- Standardized script naming to kebab-case (e.g., `install-global-tools.sh`)
- Updated Go version to 1.23.4 in apt.sh
- Updated yq version to v4.44.6 in apt.sh
- Updated lsd version to 1.1.5 in apt.sh
- Fixed Yarn installation to use modern `signed-by` method instead of deprecated `apt-key`
- Fixed `cron/update.sh` to detect Homebrew path (supports both Apple Silicon and Intel Macs)
- Fixed `destroy.sh` to be compatible with macOS (removed GNU-specific `xargs -r`)

### Removed
- Removed broken test suite (was referencing non-existent files)
- Removed example hook scripts (`scripts/custom/`)
- Removed invalid `[brew]` and `[cron]` sections from `.chezmoi.toml.tmpl`

### Fixed
- Fixed `build.sh` references to deleted directories
- Fixed Composer installation in apt.sh that would exit the entire script

## [1.0.0] - 2024-12-01

### Added
- Initial release with Chezmoi-based dotfiles management
- Cross-platform support (macOS, Linux, Windows)
- 1Password CLI integration for SSH key management
- Custom `dotfiles` CLI wrapper with subcommands
- Comprehensive `doctor` script for health checks
- Automated Homebrew updates via cron
- Project backup system with retention policy
- VS Code extensions sync
- Oh My Zsh with plugins (autosuggestions, syntax-highlighting, nvm)
- XDG Base Directory compliance
- Templated configurations for Git, Zsh, Neovim, Tmux

### Documentation
- README with quick start guide
- Installation guide with prerequisites
- Customization guide for forking
- Structure documentation
- Command reference for CLI

[Unreleased]: https://github.com/kidchenko/dotfiles/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/kidchenko/dotfiles/releases/tag/v1.0.0

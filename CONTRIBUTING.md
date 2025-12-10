# Contributing to @kidchenko's Dotfiles

Thanks for your interest in contributing! This document provides guidelines for contributing to this project.

## Ways to Contribute

- **Bug reports**: Found something broken? Open an issue
- **Feature requests**: Have an idea? Open an issue to discuss
- **Documentation**: Improve docs, fix typos, add examples
- **Code**: Fix bugs, add features, improve existing code

## Development Setup

### Prerequisites

- macOS, Linux, or Windows with WSL
- Git
- [Chezmoi](https://chezmoi.io/) installed
- [ShellCheck](https://www.shellcheck.net/) for linting

### Local Development

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/dotfiles.git
   cd dotfiles
   ```

2. **Run the build script to validate:**
   ```bash
   ./build.sh
   ```

3. **Test specific components:**
   ```bash
   ./build.sh lint      # Lint shell scripts
   ./build.sh syntax    # Check bash syntax
   ./build.sh validate  # Validate Chezmoi templates
   ./build.sh cli       # Test dotfiles CLI
   ```

### Testing Changes

Before submitting a PR:

1. **Run the full build:**
   ```bash
   ./build.sh all
   ```

2. **Test bootstrap in dry-run mode:**
   ```bash
   ./tools/bootstrap.sh --dry-run
   ```

3. **Test on a fresh environment** (optional but recommended):
   ```bash
   # Using a VM or container
   docker run -it ubuntu:latest bash
   # Then run your bootstrap
   ```

## Code Style

### Shell Scripts

- Use `#!/bin/bash` or `#!/usr/bin/env bash`
- Follow [Google's Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use `set -e` for scripts that should fail on errors
- Use kebab-case for file names: `install-tools.sh`
- Use snake_case for function names: `install_packages()`
- Add ShellCheck directives when needed: `# shellcheck disable=SC2034`

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Scripts | kebab-case | `install-tools.sh` |
| Functions | snake_case | `install_packages()` |
| Variables | UPPER_SNAKE | `DOTFILES_DIR` |
| Local vars | lower_snake | `local config_file` |

### Documentation

- Use Markdown for all documentation
- Keep lines under 100 characters when possible
- Use code blocks with language hints: ` ```bash `
- Update CHANGELOG.md for notable changes

## Pull Request Process

### Before Submitting

1. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** and commit with clear messages:
   ```bash
   git commit -m "feat: add new feature X"
   ```

3. **Update documentation** if needed (README, CLAUDE.md, docs/)

4. **Update CHANGELOG.md** under `[Unreleased]`

5. **Run the build** to ensure everything passes:
   ```bash
   ./build.sh
   ```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `style:` Formatting, no code change
- `refactor:` Code change that neither fixes a bug nor adds a feature
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

Examples:
```
feat: add Brave browser extension sync
fix: correct Homebrew path detection on Intel Macs
docs: update README with Windows instructions
refactor: extract common functions to lib/common.sh
```

### PR Checklist

- [ ] Code follows the style guidelines
- [ ] Self-review completed
- [ ] Documentation updated (if applicable)
- [ ] CHANGELOG.md updated
- [ ] Build passes locally (`./build.sh`)
- [ ] Tested on target platform(s)

## Project Structure

```
dotfiles/
├── home/                    # Chezmoi-managed dotfiles
│   ├── dot_config/          # ~/.config files
│   └── private_dot_ssh/     # SSH config templates
├── tools/                   # Management scripts
│   ├── dotfiles             # CLI tool
│   ├── bootstrap.sh         # One-line installer
│   └── os_installers/       # Platform-specific installers
├── cron/                    # Scheduled tasks
├── docs/                    # Documentation
└── .github/                 # CI and templates
```

### Key Files

| File | Purpose |
|------|---------|
| `tools/bootstrap.sh` | Entry point for new installs |
| `tools/dotfiles` | CLI wrapper for common tasks |
| `tools/doctor.sh` | Health check script |
| `Brewfile` | Homebrew packages |
| `CLAUDE.md` | AI assistant context |

## Adding New Features

### Adding a New Tool/Package

1. Add to `Brewfile` (macOS) and/or `tools/os_installers/apt.sh` (Linux)
2. Update documentation if the tool needs configuration
3. Add to doctor.sh if it should be validated

### Adding a New Dotfile

1. Create the template in `home/` with Chezmoi naming:
   - `dot_` prefix for dotfiles
   - `.tmpl` suffix for templates
   - `private_` prefix for sensitive files

2. Use Go templating for machine-specific config:
   ```
   {{ if eq .chezmoi.os "darwin" }}
   # macOS specific
   {{ end }}
   ```

### Adding a New CLI Command

1. Add function in `tools/dotfiles`: `cmd_yourcommand()`
2. Add to the case statement in `main()`
3. Add to help text
4. Document in `docs/commands/`

## Questions?

- Open an issue for questions
- Check existing issues and docs first
- Be respectful and constructive

Thank you for contributing!

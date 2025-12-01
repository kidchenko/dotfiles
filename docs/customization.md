# Customization Guide

## Fork First

Fork this repository to customize freely. Then either:
- Update `DOTFILES_REPO_URL` in `tools/bootstrap.sh`
- Use `--repo` flag during bootstrap

## Modifying Dotfiles

1. Edit templates in `home/` directory (e.g., `home/.config/nvim/init.vim.tmpl`)
2. Commit and push changes
3. Run `chezmoi apply` to update your machine

## Global Tools

Edit `~/.config/dotfiles/config.yaml`:

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

Then run:
```bash
bash tools/install_global_tools.sh
```

## VS Code Extensions

Edit `~/.config/dotfiles/vscode-extensions.txt` (one extension ID per line, `#` for comments).

Then run:
```bash
bash tools/install_vscode_extensions.sh
```

## Machine-Specific Config (Chezmoi Templates)

Create `.chezmoidata.yaml` in the repo root:

```yaml
email: "your_email@example.com"
name: "Your Name"
is_work_machine: false
```

Use in templates:

```gotemplate
# In home/.gitconfig.tmpl
[user]
  email = {{ .email | default "fallback@example.com" }}
  name = {{ .name | default "Fallback Name" }}

{{ if .is_work_machine }}
[includeIf "gitdir:~/work/"]
  path = .gitconfig-work
{{ end }}
```

See [Chezmoi templating docs](https://www.chezmoi.io/user-guide/templating/) for more.

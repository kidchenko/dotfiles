# Package install hooks

Scripts here are run by name from the `hooks:` section of
`~/.config/dotfiles/config.yaml`, around the package-install phase.

- `<name>.sh` runs on macOS/Linux, `<name>.ps1` runs on Windows.
  Provide one or both; the extension is the OS gate.
- `packages.custom.{sh,ps1}` runs post-install even when unlisted.
- Hooks re-run on every `dotfiles packages`, so they must be idempotent.
- A failing pre hook aborts the install; a failing post hook only warns.

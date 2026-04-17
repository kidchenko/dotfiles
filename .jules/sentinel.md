# Sentinel Security Journal

## 2026-04-16 - Prevent TOCTOU and Symlink Attacks via Insecure Temporary Directories

**Vulnerability:** Shell scripts were downloading executable artifacts directly
to predictable temporary paths like `/tmp/yq` or the current working directory,
which risks local privilege escalation, symlink attacks, and overwriting
existing files when executed with elevated privileges (`sudo`).
**Learning:** Hardcoded temporary paths (`/tmp/...`) are insecure and
susceptible to symlink hijacking by local attackers. Additionally, downloading
directly to the current directory is poor practice and pollutes the workspace
or risks naming collisions.
**Prevention:** Always use securely generated random directories (e.g.,
`TMP_DIR=$(mktemp -d)`) wrapped in a subshell `(...)` and paired with a local
trap (`trap 'rm -rf "$TMP_DIR"' EXIT`) to ensure isolation and automatic
cleanup upon exit.

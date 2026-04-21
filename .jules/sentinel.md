## 2026-02-24 - Insecure Backup Permissions
**Vulnerability:** Backup archives created by `tools/backup-projects.sh` were readable by all users on the system (0644 default permissions). These archives contain sensitive project files and potentially secrets.
**Learning:** Shell scripts using `zip` or `tar` often inherit default umask settings, which are typically permissive. Creating backups in shared environments (even multi-user home machines) requires explicit permission handling.
**Prevention:** Enforce `umask 0077` (or strict `chmod`) when creating sensitive files or archives in shell scripts. Always assume the default environment is insecure.
# Sentinel Journal

## 2026-04-15 - Prevent TOCTOU in SSH Key Restoration

**Vulnerability:** A Time-of-Check to Time-of-Use (TOCTOU) vulnerability where an
SSH private key is briefly world-readable upon creation before `chmod 600` is
applied.

**Learning:** Redirecting output to a file creates the file with default
permissions (often `644`), which exposes sensitive data for a fraction of a
second.

**Prevention:** Wrap commands that create sensitive files in a subshell using
`umask 077` to ensure the file is created with secure permissions (`600`)
natively.

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

## 2026-04-20 - Insecure executable artifact download location

**Vulnerability:** Downloaded executable script (`composer-setup.php`) directly
to the current working directory in an installation script.

**Learning:** Downloading files directly to the current directory is insecure
because it might overwrite existing files or leave executable artifacts
susceptible to modification before execution, especially in scripts that may run
with elevated privileges.

**Prevention:** Always use securely generated isolated temporary directories via
`mktemp -d`, and wrap the setup in a subshell `(...)` with an automatic `trap`
to ensure secure handling and cleanup.

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

## 2026-04-18 - Prevent Insecure Artifact Downloads in APT Setup

**Vulnerability:** Shell scripts were downloading executable artifacts directly
to the current working directory, which risks overwriting existing files or
executing attacker-controlled binaries when executed with elevated privileges
(`sudo`).

**Learning:** Downloading directly to the current directory is poor practice
and pollutes the workspace or risks naming collisions.

**Prevention:** Always use securely generated random directories (e.g.,
`TMP_DIR=$(mktemp -d)`) wrapped in a subshell `(...)` and paired with a local
trap (`trap 'rm -rf "$TMP_DIR"' EXIT`) to ensure isolation and automatic
cleanup upon exit.

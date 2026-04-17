# Sentinel Security Journal

## 2025-04-17 - Insecure Temporary Files and Direct Downloads in Installation Scripts

**Vulnerability:** Predictable temporary files and direct downloads to the
current working directory in `tools/os_installers/apt.sh`.

**Learning:** Installation scripts often download artifacts. Using predictable
paths like `/tmp/yq` allows local attackers to overwrite or predict the file,
leading to potential privilege escalation (especially since the script uses
`sudo`). Additionally, downloading archives directly to the current working
directory is an insecure practice as it risks overwriting existing files or
leaving artifacts behind.

**Prevention:** Always use securely generated temporary directories via
`mktemp -d` within a subshell, and use a `trap 'rm -rf "$TMP_DIR"' EXIT` for
safe cleanup, rather than predictable paths or the current directory.

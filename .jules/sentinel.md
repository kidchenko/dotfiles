# Sentinel Journal

## 2023-10-25 - Predictable temporary file path vulnerability in installer

**Vulnerability:** Installation scripts downloaded files directly to the current
working directory or to predictable temporary file locations (e.g. `/tmp/yq`),
which could allow an attacker to predict and poison files or leverage symlink
attacks.
**Learning:** These paths create a Time-of-Check to Time-of-Use (TOCTOU)
vulnerability where an attacker can replace a downloaded binary with a malicious
one before it is executed or moved by an administrative command (`sudo`). Using
the current working directory is risky since its permissions are not strictly
isolated and could cause accidental overwrites.
**Prevention:** Always use dynamically and securely created temporary
directories generated with `mktemp -d` for installation operations. Wrap the
download and extraction commands inside a subshell `(...)` and assign a local
trap (e.g., `trap 'rm -rf "$TMP_DIR"' EXIT`) to guarantee proper cleanup
independently.

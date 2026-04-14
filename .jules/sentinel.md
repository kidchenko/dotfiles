# Sentinel Journal

## 2025-02-14 - Insecure File and Directory Usage Fix

**Vulnerability:** Predictable file creation and current working directory usage.

**Learning:** Downloading files directly into the current directory or a
predictable temporary path like `/tmp/` without specific permissions can allow
local privilege escalation or symlink attacks.

**Prevention:** Use `mktemp -d` to create a secure temporary directory, wrap
logic in a subshell `(...)` and set a cleanup trap `trap 'rm -rf "$TMP_DIR"' EXIT`.

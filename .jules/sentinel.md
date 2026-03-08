## 2024-05-18 - Insecure Temporary File Path
**Vulnerability:** Hardcoded predictable temporary file paths (e.g., `/tmp/yq`) in shell scripts executing with elevated privileges (`sudo`).
**Learning:** Using predictable paths allows local privilege escalation and symlink attacks. Attackers can pre-create symlinks pointing to critical system files.
**Prevention:** Always use securely generated random directories like `mktemp -d` to handle temporary files securely.

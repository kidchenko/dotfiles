## 2024-05-24 - [Local Privilege Escalation in Installation Scripts]
**Vulnerability:** Predictable temporary file paths (`/tmp/yq`) used during downloading executables, which were then processed with `sudo`.
**Learning:** Hardcoding shared temporary directories (`/tmp`) allows local attackers to pre-create files or symlinks (TOCTOU attacks). This is especially critical when combined with `sudo` execution.
**Prevention:** Always use securely generated, random temporary directories created by `mktemp -d` and paired with an `EXIT` trap for automated cleanup (e.g., `YQ_TMP_DIR=$(mktemp -d); trap "rm -rf '$YQ_TMP_DIR'" EXIT`).

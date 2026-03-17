## 2025-02-14 - Predictable Temporary File Paths

**Vulnerability:** Predictable temporary file paths (`/tmp/yq`) were used when downloading and installing external binaries, combined with a `sudo` operation (`sudo mv /tmp/yq /usr/local/bin/yq`).
**Learning:** Hardcoding files in shared directories like `/tmp` makes the system vulnerable to symlink attacks or local privilege escalation. An attacker could preemptively create a symlink at `/tmp/yq` pointing to a critical system file, which `sudo mv` or `sudo chmod` would then inadvertently overwrite or modify.
**Prevention:** Always use securely generated temporary directories (e.g., `mktemp -d`) for downloading temporary files, and delete them after use.

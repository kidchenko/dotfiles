## 2024-05-15 - Insecure Temporary File Creation in Installer Script
**Vulnerability:** Hardcoded temporary file path `/tmp/yq` used before a `sudo mv` operation, which can lead to symlink attacks or arbitrary code execution by local attackers.
**Learning:** Hardcoding paths in world-writable directories like `/tmp` is dangerous, especially in scripts that escalate privileges (`sudo`). An attacker can exploit this predictable path before the script has a chance to secure it.
**Prevention:** Always use securely generated random directories (e.g., `mktemp -d`) for temporary files, especially in privileged operations.

## 2025-03-25 - [CRITICAL] Insecure File Downloads in apt.sh
**Vulnerability:** The `apt.sh` script downloaded executables (like `yq`) directly to predictably named, globally writable paths (e.g., `/tmp/yq`), and generated temporary scripts (`composer-setup.php`) in the local working directory.
**Learning:** This exposes the system to symlink attacks or malicious file overwriting if an attacker gains local access, or pollution of the user's current working directory.
**Prevention:** Always use dynamically generated, securely permissioned temporary directories (e.g., using `mktemp -d`) and properly configure cleanup actions using `trap` statements when handling temporary file downloads in automation scripts.

## 2024-02-12 - Insecure SSH Key Creation (TOCTOU)
**Vulnerability:** `tools/setup-ssh-keys.sh` created sensitive SSH private keys with default permissions (usually 664/644) before restricting them with `chmod 600`. This created a race condition (TOCTOU) where the key was briefly readable by other users.
**Learning:** Standard shell redirection (`> file`) uses the default umask (typically 022 or 002), resulting in world-readable files for a split second. Relying on a subsequent `chmod` is insecure for sensitive data.
**Prevention:** Always wrap sensitive file creation commands in a subshell with `umask 077` (e.g., `(umask 077; cmd > file)`). This ensures the file is created with 600 permissions atomically.

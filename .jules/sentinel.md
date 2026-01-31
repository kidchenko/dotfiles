## 2025-01-31 - Secure File Creation with 1Password CLI
**Vulnerability:** Race condition in `tools/setup-ssh-keys.sh` where private keys were written to disk with default permissions before being restricted, exposing them to other users on the system.
**Learning:** Shell redirection `>` creates files with default umask (often 022/644) before `chmod` can run.
**Prevention:** Use `(umask 077; command > file)` subshell pattern to ensure sensitive files are created with 0600 permissions atomically.

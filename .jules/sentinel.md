## 2025-02-14 - Shell Script TOCTOU Vulnerability
**Vulnerability:** SSH keys were created with default permissions (often world-readable) before being restricted with `chmod`, creating a race condition (TOCTOU).
**Learning:** Shell scripts using `>` redirection to create sensitive files inherit the current umask, leading to insecure default permissions.
**Prevention:** Always use `umask 077` in a subshell `(umask 077; command > file)` when creating sensitive files in shell scripts.

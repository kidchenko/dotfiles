## 2025-02-11 - Secure File Creation with umask
**Vulnerability:** SSH private keys were created with default umask (often 022/002), making them world-readable for a brief window before `chmod` (TOCTOU race condition).
**Learning:** Redirection `>` in shell scripts respects current umask, creating files with potentially insecure permissions by default. `chmod` after creation is insufficient for high-security files.
**Prevention:** Wrap sensitive file creation commands in a subshell with `umask 077` (e.g., `(umask 077; command > file)`). This ensures atomic secure creation.

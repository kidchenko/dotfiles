## 2024-05-22 - TOCTOU Race Condition in File Permissions
**Vulnerability:** SSH private keys were written to disk with default permissions and then restricted with `chmod` immediately after. This creates a Time-of-Check-Time-of-Use (TOCTOU) race condition window where the file is world-readable (depending on system umask).
**Learning:** `chmod` is not atomic with file creation. Relying on it for sensitive files leaves a security gap.
**Prevention:** Use `umask` in a subshell or the `install` command (if portable) to ensure files are created with restrictive permissions from the start. Example: `(umask 077; echo secret > file)`

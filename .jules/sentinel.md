# Sentinel's Journal

## 2025-02-13 - Secure File Creation in Shell Scripts
**Vulnerability:** SSH private keys were created with default umask (often 022, resulting in 644/world-readable) before being restricted with `chmod 600`. This created a race condition where the key was briefly readable by other users.
**Learning:** Shell redirection (`>`) and `mkdir` adhere to the process's `umask` at the time of execution. `chmod` after creation leaves a window of vulnerability.
**Prevention:** Use `(umask 077 && mkdir ...)` for directories and `(umask 077; command > file)` for files to ensure atomic secure permissions. Remove existing files before writing if sensitive to ensure new inode creation with correct permissions.

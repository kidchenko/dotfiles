## 2025-02-08 - TOCTOU Race Condition in File Creation
**Vulnerability:** The SSH private key was being created with default permissions (potentially world-readable) before `chmod 600` was applied. This created a race condition where the key could be read by other users on the system.
**Learning:** Shell redirection (`>`) creates files with the current `umask` before any subsequent `chmod` command is executed.
**Prevention:** Use `umask 077` in a subshell when creating sensitive files to ensure they are created with restricted permissions from the start. Example: `(umask 077; command > file)`.

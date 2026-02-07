## 2025-02-07 - Insecure File Creation for Sensitive Data
**Vulnerability:** Private SSH keys were created with default umask permissions (often 0644 or 0664) before being restricted to 0600, creating a race condition (TOCTOU) where the file could be read by other users during the creation window.
**Learning:** Shell redirection (`>`) creates the file before `chmod` is executed, using the process's default umask. Explicitly setting `chmod` afterwards is insufficient for highly sensitive files on multi-user systems.
**Prevention:** Wrap sensitive file creation commands in a subshell with `umask 077` (or `umask 0177` for executable scripts) to ensure the file is created with restrictive permissions (0600) from the start.

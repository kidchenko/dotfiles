## 2025-02-16 - TOCTOU Race Condition in Shell Scripts
**Vulnerability:** Private SSH keys were created using redirection (`> file`) before restricting permissions (`chmod 600`), leaving a race window where keys were world-readable.
**Learning:** Shell redirection creates files with default umask permissions (often 644) *before* any subsequent `chmod` command runs.
**Prevention:** Use `(umask 077; command > file)` in a subshell to ensure files are created with restrictive permissions atomically. Also ensure existing files are removed before recreation.

## 2025-02-03 - File Creation Race Conditions
**Vulnerability:** SSH private keys were created with default umask permissions (world-readable) before being restricted with `chmod`.
**Learning:** Shell redirection (`>`) creates files with default umask permissions immediately. `chmod` after creation leaves a window of exposure (race condition).
**Prevention:** Use `umask 077` in a subshell or block before creating sensitive files to ensure they are born secure.

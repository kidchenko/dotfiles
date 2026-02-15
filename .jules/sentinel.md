## 2024-05-22 - SSH Key TOCTOU Vulnerability
**Vulnerability:** SSH private keys were created with default permissions (likely 644/664) and then chmod'ed to 600, creating a Time-of-Check Time-of-Use (TOCTOU) race condition where the key was briefly world-readable.
**Learning:** Shell redirection (`>`) creates files with default umask permissions before any subsequent `chmod` command can run.
**Prevention:** Use `(umask 077 && command > file)` in a subshell to ensure the file is created with restrictive permissions (600) from the very beginning.

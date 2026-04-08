## 2024-04-08 - [TOCTOU in SSH Key Generation]
**Vulnerability:** SSH private keys were temporarily written to disk with default permissions before `chmod 600` was applied, creating a Time-of-Check to Time-of-Use (TOCTOU) vulnerability where other users could theoretically read the key in the brief window between creation and permission change.
**Learning:** Shell redirection (`>`) creates files with default umask permissions. Applying `chmod` immediately after still leaves a race condition.
**Prevention:** Shell scripts handling sensitive data must enforce strict access control using `umask 077` (globally or in a subshell) before file creation to prevent TOCTOU vulnerabilities.

## 2024-02-10 - [SSH Key Creation Race Condition]
**Vulnerability:** SSH private keys were briefly world-readable during creation because `umask` was not restricted. The `op read ... > file` command created the file with default permissions (often 644/664), and `chmod 600` was only applied afterward.
**Learning:** Shell redirection creates files before `chmod` runs. This creates a Time-of-Check to Time-of-Use (TOCTOU) window where sensitive data is exposed.
**Prevention:** Always wrap sensitive file creation commands in a subshell with restricted umask: `(umask 077; command > sensitive_file)`. This ensures the file is born secure.

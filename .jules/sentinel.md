## 2024-05-24 - [CRITICAL] Prevent TOCTOU Vulnerabilities During SSH Key Creation
**Vulnerability:** Private SSH keys were written to disk with the system default umask before `chmod 600` was explicitly applied, creating a brief window where the file might be readable by other users.
**Learning:** Calling `chmod` after file creation is insufficient to prevent Time-of-Check to Time-of-Use (TOCTOU) vulnerabilities for highly sensitive files like SSH keys.
**Prevention:** Always enforce strict permissions during file creation by using `umask 077` within a subshell (`(...)`) to securely create the directory (`700`) and the file (`600`) without affecting the parent shell's umask.

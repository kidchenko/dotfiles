## 2024-05-18 - [CRITICAL] Prevent TOCTOU vulnerabilities in file creation
**Title:** Prevent TOCTOU vulnerabilities in file creation
**Vulnerability:** Shell scripts creating files containing sensitive data (e.g., SSH private keys) and then calling `chmod 600` on them leave the files briefly readable based on the system's umask setting. This creates a Time-of-Check to Time-of-Use (TOCTOU) vulnerability where an attacker could read the sensitive data between file creation and the `chmod` operation.
**Learning:** The default umask does not restrict file read access enough for sensitive files. Explicitly invoking `chmod` after creation is insufficient to protect sensitive data during that brief window.
**Prevention:** Shell scripts handling sensitive data must enforce strict access control (permissions 600/700) using `umask 077` (globally or in a subshell) before file creation to prevent TOCTOU vulnerabilities.

## 2024-05-09 - [TOCTOU in SSH Key Creation]
**Vulnerability:** Time-of-Check to Time-of-Use (TOCTOU) vulnerability where the private SSH key was briefly readable.
**Learning:** `chmod 600 "$PRIVATE_KEY_FILE"` executed after creating the file means the key is created with default permissions (often 0644), leaving a small window where another process could read the contents.
**Prevention:** Shell scripts handling sensitive data must enforce strict access control (permissions 600/700) using `umask 077` (globally or in a subshell) before file creation.

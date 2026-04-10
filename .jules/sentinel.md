## 2026-04-10 - [TOCTOU vulnerability in SSH key generation]

**Vulnerability:** Private SSH keys written to disk using shell redirection (`> "$PRIVATE_KEY_FILE"`) followed by `chmod 600`.
**Learning:** Shell redirection creates the file according to the system's `umask`. If the `umask` allows, the file might briefly be readable by other users before `chmod 600` executes, causing a Time-of-Check to Time-of-Use (TOCTOU) vulnerability.
**Prevention:** Wrap file creation steps that handle sensitive data in a subshell using `(umask 077 && command > file)` so that the file is created with secure permissions right from the start.

# Sentinel Journal

## 2025-04-12 - Prevent TOCTOU vulnerabilities in file creation

**Vulnerability:** SSH private keys and other sensitive files were being written
to disk and subsequently restricted using `chmod 600`. This creates a
Time-of-Check to Time-of-Use (TOCTOU) race condition where the file is briefly
readable with default permissions before `chmod` executes.
**Learning:** Shell scripts generating sensitive files must ensure the file is
created with secure permissions from the moment of creation. Explicitly calling
`chmod` after creation leaves a brief window for local privilege escalation or
unauthorized read access.
**Prevention:** Wrap the file creation logic in a subshell `(...)` and set
`umask 077` immediately before the command that writes the file. This ensures
the file is created with 600 permissions without affecting the global script's
umask.

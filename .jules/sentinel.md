# Sentinel Journal

## 2026-04-15 - Prevent TOCTOU in SSH Key Restoration

**Vulnerability:** A Time-of-Check to Time-of-Use (TOCTOU) vulnerability where an
SSH private key is briefly world-readable upon creation before `chmod 600` is
applied.

**Learning:** Redirecting output to a file creates the file with default
permissions (often `644`), which exposes sensitive data for a fraction of a
second.

**Prevention:** Wrap commands that create sensitive files in a subshell using
`umask 077` to ensure the file is created with secure permissions (`600`)
natively.

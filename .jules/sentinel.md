## 2024-10-24 - Shell Script Race Conditions
**Vulnerability:** Found a Time-of-Check Time-of-Use (TOCTOU) race condition in `tools/setup-ssh-keys.sh` where a private key was written to disk with default permissions before being restricted with `chmod`.
**Learning:** Shell scripts often default to permissive `umask` (e.g., 022), making files world-readable for a brief window during creation.
**Prevention:** Always use `umask 077` in a subshell before writing sensitive files to ensure they are created with restricted permissions (0600) atomically.

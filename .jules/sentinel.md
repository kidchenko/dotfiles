## 2026-02-21 - Insecure Backup Permissions
**Vulnerability:** `tools/backup-projects.sh` created project backups with default umask permissions (often 644/755), making them world-readable.
**Learning:** Scripts generating sensitive artifacts (backups, keys, logs) must explicitly set permissions. Default umask is insufficient for privacy.
**Prevention:** Enforce `umask 077` at the start of any script that handles sensitive data or artifacts.

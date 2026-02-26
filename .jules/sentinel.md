## 2026-02-26 - Insecure Backup Permissions
**Vulnerability:** The backup script `tools/backup-projects.sh` created project archives and log files with default umask permissions (often 644/755), making them readable by other users on the system.
**Learning:** Shell scripts creating sensitive archives often default to system umask, which is usually designed for collaboration, not secrecy.
**Prevention:** Explicitly set `umask 077` in a subshell before running archival commands like `zip` or `tar`, and use `chmod 700` on sensitive directories immediately after creation.

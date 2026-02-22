## 2026-02-22 - Insecure Default Permissions on Backups
**Vulnerability:** The `tools/backup-projects.sh` script created zip archives with default permissions (often `644` or `664`), allowing other users on the system to read potentially sensitive project backups.
**Learning:** Shell scripts using tools like `zip` or `tar` do not automatically restrict permissions of the output file unless `umask` is set.
**Prevention:** Always set `umask 077` at the beginning of shell scripts that generate sensitive files or directories to ensure they are private by default.

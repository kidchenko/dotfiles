## 2025-01-20 - [Insecure File Permissions on Unencrypted Backups]
**Vulnerability:** The `tools/backup-projects.sh` script creates unencrypted zip archives of project folders containing git repositories, which may include sensitive data like tokens or secrets, but doesn't explicitly secure the resulting backup files or the backup directories.

**Learning:** Shell scripts handling sensitive archives need explicit permission management, especially when the default `umask` of the user might be overly permissive (like `0022`), making backups readable by other users on the system.

**Prevention:** Ensure scripts creating sensitive backup archives explicitly use `umask 077` within the creation subshell and explicitly `chmod 700` any created backup directories to restrict read/write access to the file owner only.

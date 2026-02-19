# Sentinel's Journal

## 2026-02-19 - Insecure Backup Permissions
**Vulnerability:** Backup archives containing sensitive project data were created with default `umask` (often 022), making them readable by other users on the system (`-rw-rw-r--`).
**Learning:** Even in single-user systems, assuming default permissions are secure is risky. Tools creating sensitive artifacts must explicitly enforce restrictive permissions.
**Prevention:** Added `umask 077` to `tools/backup-projects.sh` and explicitly `chmod 700` on backup directories to ensure least privilege.

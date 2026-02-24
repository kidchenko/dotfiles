## 2026-02-24 - Insecure Backup Permissions
**Vulnerability:** Backup archives created by `tools/backup-projects.sh` were readable by all users on the system (0644 default permissions). These archives contain sensitive project files and potentially secrets.
**Learning:** Shell scripts using `zip` or `tar` often inherit default umask settings, which are typically permissive. Creating backups in shared environments (even multi-user home machines) requires explicit permission handling.
**Prevention:** Enforce `umask 0077` (or strict `chmod`) when creating sensitive files or archives in shell scripts. Always assume the default environment is insecure.

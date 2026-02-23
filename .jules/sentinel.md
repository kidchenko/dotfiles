## 2026-02-23 - Insecure Permissions on Backups
**Vulnerability:** `tools/backup-projects.sh` created backup zip archives and logs with default umask permissions (often 022/644), making them world-readable on multi-user systems. These backups contain source code and logs contain remote URLs (potentially with tokens).
**Learning:** Shell scripts creating sensitive files must explicitly manage permissions, as default system umasks are often permissive.
**Prevention:** Use `umask 077` at the start of scripts handling sensitive data to ensure files are only readable by the owner by default.

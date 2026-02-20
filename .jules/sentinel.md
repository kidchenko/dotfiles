## 2024-05-24 - Secure Backup Permissions
**Vulnerability:** Backup archives created by `zip` without explicit permissions were world-readable (depending on umask), exposing sensitive project data.
**Learning:** `mkdir -p` and `zip` respect the process `umask`, but relying on system defaults is insecure for sensitive data.
**Prevention:** Explicitly set `umask 077` at the start of sensitive operations and use `chmod` to enforce restrictive permissions (600/700) on critical artifacts.

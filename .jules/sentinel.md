## 2024-05-24 - [CRITICAL] Fix predictable and insecure temporary file paths
**Vulnerability:** Installation scripts (`tools/os_installers/apt.sh`) downloaded files to predictable locations (`/tmp/yq`) or the current working directory, which risks symlink attacks and overwriting existing files, especially when running as `sudo`.
**Learning:** Using elevated privileges with predictable paths or working directories can lead to local privilege escalation.
**Prevention:** Always use securely generated random directories like `mktemp -d` to prevent local privilege escalation and symlink attacks.

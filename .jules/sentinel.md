## 2025-03-07 - [Fix Insecure Temporary File Usage in OS Installers]
**Vulnerability:** Predictable temporary file locations (`/tmp/yq`) and current working directory downloads during package installation in `tools/os_installers/apt.sh`.
**Learning:** Using predictable paths like `/tmp/filename` allows local privilege escalation and symlink attacks. Downloading directly to the current working directory is untidy and may leave artifacts behind or conflict with existing files.
**Prevention:** Always use securely generated temporary directories like `mktemp -d` to handle downloads and intermediate files during scripts.

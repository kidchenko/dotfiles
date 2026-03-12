## 2026-03-12 - Prevent Symlink Attacks in Package Installers
**Vulnerability:** Hardcoded, predictable temporary file paths (e.g., `/tmp/yq`) used prior to `sudo mv` operations for binary installation.
**Learning:** Malicious local users can create symlinks at predictable `/tmp` locations before an installation script executes. When the elevated script (using `sudo`) writes to or moves from these predictable paths, it can be exploited to overwrite critical system files, leading to privilege escalation or denial of service.
**Prevention:** Always use `mktemp -d` to create secure, unpredictable temporary directories for downloading or processing files, especially when running with elevated privileges or performing cross-user operations.

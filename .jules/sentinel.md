## 2025-03-05 - [Predictable Temporary File Vulnerability in apt.sh]
**Vulnerability:** A hardcoded temporary file path (`/tmp/yq`) was used for downloading and installing the `yq` binary. This made the script vulnerable to symlink attacks or local privilege escalation if another user created a malicious file at that location beforehand.
**Learning:** Hardcoding paths in shared directories like `/tmp` within scripts executing with `sudo` is dangerous and exposes systems to exploitation by less privileged users.
**Prevention:** Always use securely generated random directories with tools like `mktemp -d` when dealing with temporary files, especially in scripts that install system-wide binaries or run with elevated privileges.

## 2024-03-04 - [Avoid Insecure Temporary Files in Scripts]
**Vulnerability:** Use of predictable temporary files like `/tmp/yq` in shell scripts with elevated privileges (sudo).
**Learning:** Hardcoding `/tmp/...` paths makes scripts vulnerable to symlink attacks or local privilege escalation when another user creates that file first.
**Prevention:** Always use securely generated random directories like `mktemp -d` to handle temporary files safely, especially when using `sudo` or downloading binaries.

## 2024-12-19 - Hardcoded temporary paths (`/tmp/`)

**Vulnerability:** A script was downloading `yq` to a fixed path: `/tmp/yq` before changing its permissions and moving it to `/usr/local/bin/yq`. This creates a race condition/symlink attack vulnerability. If an attacker predicts the path and creates a malicious file or symlink at `/tmp/yq` before the download happens, `wget` might overwrite the attacker's file, but `mv` and `chmod` execute with elevated permissions (`sudo`), which allows arbitrary files to be modified, leading to local privilege escalation.
**Learning:** Hardcoded `/tmp` paths should not be used in shell scripts, especially when downloading or manipulating files with root (`sudo`) privileges.
**Prevention:** Use a securely generated temporary directory via `mktemp -d` to securely store downloaded or intermediate files, rather than relying on predictable paths like `/tmp/filename`.

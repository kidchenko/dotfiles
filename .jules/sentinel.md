## 2024-04-05 - Predictable Temporary File Path in Installation Scripts

**Vulnerability:** Predictable temporary file paths (`/tmp/yq`) are used for downloading files before moving them to privileged directories (`/usr/local/bin`) in `tools/os_installers/apt.sh`.
**Learning:** Hardcoding a predictable file path in `/tmp` makes the script vulnerable to symlink attacks. An attacker could pre-create `/tmp/yq` as a symlink pointing to a sensitive file, causing the subsequent `sudo mv` command to overwrite the target file or potentially leading to arbitrary code execution if the downloaded binary is a payload that gets moved to a privileged path.
**Prevention:** Always use secure, randomized temporary directories using `mktemp -d` when downloading or processing temporary files. Avoid hardcoding predictable file paths, especially when mixing unprivileged commands (`wget`) with privileged commands (`sudo`). Use a local cleanup trap inside a subshell for temporary directory removal.

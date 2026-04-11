# Sentinel Journal

## 2024-04-11 - [Insecure Temporary File Usage for yq Download]

**Vulnerability:** Predictable temporary file path `/tmp/yq` used during
download and installation in `tools/os_installers/apt.sh`.

**Learning:** Hardcoding `/tmp/yq` allows a malicious local user to pre-create
`/tmp/yq` (e.g., as a symlink or with specific permissions), leading to potential
privilege escalation or overriding of files when `sudo mv /tmp/yq ...` is
executed.

**Prevention:** Always use securely generated random directories like
`mktemp -d` and wrap in a subshell with a cleanup trap to prevent local
privilege escalation and symlink attacks.

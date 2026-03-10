## 2024-05-24 - Predictable Temporary File Path in Sudo Operations
**Vulnerability:** The script `tools/os_installers/apt.sh` downloaded `yq` to a hardcoded predictable temporary path (`/tmp/yq`) and then moved it using elevated privileges (`sudo mv`). This could be exploited via a symlink attack for local privilege escalation.
**Learning:** Hardcoded `/tmp/` files used with elevated privileges expose systems to symlink attacks, a pattern observed in the OS installation scripts.
**Prevention:** Always use securely generated random directories like `mktemp -d` to stage downloaded files before performing elevated operations.

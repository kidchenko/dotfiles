## 2025-01-20 - [Hardcoded Predictable Temp File Path]
**Vulnerability:** In `tools/os_installers/apt.sh`, `yq` was downloaded directly to a hardcoded predictable temporary file path `/tmp/yq` and then moved using elevated privileges (`sudo mv`).
**Learning:** Hardcoding paths like `/tmp/filename` creates a risk for local privilege escalation and symlink attacks. Attackers can pre-create the file as a symlink pointing to a sensitive system file, which the script would then overwrite when executing as root.
**Prevention:** Avoid hardcoding predictable temporary file paths in shell scripts. Always use securely generated random directories like `mktemp -d` to handle downloads or intermediate files securely.

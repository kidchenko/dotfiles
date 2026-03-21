## 2024-05-18 - [Predictable /tmp paths & insecure working directory usage]
**Vulnerability:** The apt.sh script downloaded packages into a predictable location (/tmp/yq) or the current working directory. This creates symlink attack risks (for predictable paths) and risks overwriting existing files or executing attacker-controlled binaries.
**Learning:** Hardcoded, predictable /tmp paths can be exploited by an unprivileged user by symlinking the path to a sensitive file. Downloading to the current working directory risks writing files where they shouldn't be.
**Prevention:** Always use securely generated random directories like `mktemp -d` to handle downloads instead of relying on the current working directory or predictable temporary file paths.

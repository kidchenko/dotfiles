## 2024-05-24 - [Avoid predictable temporary paths in shared locations like /tmp]
**Vulnerability:** A script uses a hardcoded, predictable path (e.g., `/tmp/yq`) when downloading tools, which could lead to a symlink attack or unauthorized file modification, especially when running with elevated privileges (like `sudo mv /tmp/yq /usr/local/bin/yq`).
**Learning:** Hardcoding paths in world-writable directories (`/tmp`) makes the script vulnerable to a local attacker pre-creating the file (or a symlink) to perform malicious actions.
**Prevention:** Always use securely generated temporary directories (e.g., `mktemp -d`) coupled with a cleanup trap to store downloaded files before moving them to their final destination.

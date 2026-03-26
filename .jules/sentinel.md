## 2024-05-18 - [Secure Temp Downloads in Setup Scripts]
**Vulnerability:** Shell scripts downloading binaries directly to the current working directory (`wget ... -O file`) or predictable locations like `/tmp/yq` instead of secure temporary directories.
**Learning:** This is a recurring pattern in OS installer scripts (`apt.sh`) that exposes users to symlink attacks or overwriting unintended files, especially dangerous when using `sudo mv` afterwards.
**Prevention:** Always use securely generated isolated temporary directories for script downloads: `TMP_DIR=$(mktemp -d)` paired with `trap 'rm -rf "$TMP_DIR"' EXIT`. Never hardcode `/tmp/` paths or download indiscriminately to the current working directory.

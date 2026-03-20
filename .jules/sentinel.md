## 2024-03-20 - [Hardcoded and Predictable Temporary File Paths]
**Vulnerability:** Use of predictable temporary file paths like `/tmp/yq`, and downloading executables/archives (`go...tar.gz`, `lsd...deb`) into the current working directory.
**Learning:** These paths can be predicted by an attacker to conduct a symlink attack or file overwriting, especially when operations like `sudo mv /tmp/yq ...` or `sudo dpkg -i ...` are performed, which can lead to local privilege escalation. Downloading to `cwd` can also clutter the directory or overwrite existing files unintentionally.
**Prevention:** Use `mktemp -d` to securely generate a random, isolated temporary directory for downloading and manipulating files before moving them or installing them.

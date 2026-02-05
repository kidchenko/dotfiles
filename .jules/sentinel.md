## 2024-05-22 - Secure File Creation in Shell Scripts
**Vulnerability:** TOCTOU race condition when creating sensitive files (like SSH keys) using redirection (`>`) followed by `chmod`.
**Learning:** Files created via redirection inherit default permissions (usually 644/666) before `chmod` runs, leaving a window where they are world-readable.
**Prevention:** Use `umask` inside a subshell to strictly control permissions at creation time: `(umask 077; command > file)`.

## 2025-02-02 - Secure File Creation with Shell Redirection
**Vulnerability:** SSH private keys restored from 1Password via `op read > file` were created with default umask permissions before `chmod` was applied, creating a race condition.
**Learning:** Shell redirection creates files before `chmod` can act. Even in "personal" dotfiles, this can expose secrets on multi-user systems (e.g., shared servers).
**Prevention:** Use `(umask 077 && command > file)` to ensure files are born secure.

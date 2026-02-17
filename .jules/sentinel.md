## 2026-02-17 - Insecure Temporary Files & Shell Argument Injection
**Vulnerability:**
1. Backup script created directories and files in default umask (likely 755/644), exposing sensitive source code backups to other users.
2. Shell script passed exclude patterns as a space-separated string to `zip`, causing incorrect argument parsing if patterns contained spaces (argument injection/logic error).

**Learning:**
- Always explicitly set directory permissions (`chmod 700`) for sensitive data directories.
- Use `umask 077` in a subshell when creating sensitive files to ensure they are private by default (0600).
- In Bash, always use arrays (`"${arr[@]}"`) for passing lists of arguments to commands to handle spaces correctly. String concatenation is dangerous.

**Prevention:**
- Use `install -d -m 700` or `mkdir` + `chmod 700` for private directories.
- Review all shell scripts for unquoted variable expansions in command arguments.
- Prefer array handling over string manipulation for command arguments.

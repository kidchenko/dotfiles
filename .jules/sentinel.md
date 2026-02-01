## 2024-05-22 - [SSH Private Key Race Condition]
**Vulnerability:** Found a TOCTOU (Time-of-Check to Time-of-Use) race condition in `tools/setup-ssh-keys.sh`. The script created the private key file using output redirection (`>`) which uses the default umask (typically 022), resulting in the file being world-readable for a brief window before `chmod 600` was executed.
**Learning:** Shell redirection and standard file creation tools respect the current `umask`. Relying on a subsequent `chmod` to secure sensitive files leaves a window of exposure.
**Prevention:** Always set `umask 077` (or similar restrictive mask) *before* creating sensitive files in shell scripts to ensure they are born secure. Restore the original umask afterwards if necessary.

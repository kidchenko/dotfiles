## 2025-02-20 - TOCTOU Vulnerability in SSH Key Restoration
**Vulnerability:** Time-of-Check to Time-of-Use (TOCTOU) when restoring SSH private keys from 1Password.
**Learning:** Writing sensitive data to a file using default permissions and then using `chmod 600` leaves the file briefly readable by other users on the system between the write and the chmod.
**Prevention:** Use a subshell with `umask 077` (e.g., `(umask 077 && command > file)`) to ensure the file is created with secure permissions (600) from the start.

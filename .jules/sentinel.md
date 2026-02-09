# Sentinel's Journal

## 2024-05-22 - TOCTOU Race Condition in File Creation
**Vulnerability:** Found a Time-of-Check to Time-of-Use (TOCTOU) vulnerability in `tools/setup-ssh-keys.sh` where sensitive SSH keys were created with default permissions (potentially world-readable) before being restricted with `chmod`.
**Learning:** Even with a subsequent `chmod`, there is a small window where a file is accessible to other users on the system if created with default `umask`.
**Prevention:** Always use `umask 077` in a subshell when creating sensitive files or directories to ensure they are private from the moment of creation.

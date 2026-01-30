## 2026-01-30 - Leaking Git Credentials in Logs
**Vulnerability:** Git remote URLs containing authentication tokens were being logged to plain text files.
**Learning:** Utilities that aggregate info about git repositories (like backup scripts) often indiscriminately log `git remote get-url`. When users use PATs (Personal Access Tokens) in URLs, these secrets are leaked.
**Prevention:** Always sanitize URLs (redact `user:password@`) before logging or displaying them.


- **Data handled**: A hash of whatever the caller digested; the hash can identify content, so the caller decides whether storing it is acceptable.
- **Storage**: None; the caller stores the string (the daemon uses `transcript_lines.line_hash` and `ConfigChange.file_sha256`).
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the returned string.


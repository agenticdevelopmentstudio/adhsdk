
- **Data collected**: the hook payload as Claude Code sent it, the account name and OAuth login email returned by the injected closures, and a process snapshot that includes `argv`, the working directory, user and group ids, `hostname`, `PATH`, `HOME`, `USER`, `LOGNAME`, `TMPDIR`, `PWD` and terminal identifiers.
- **Storage**: one JSON file in the drop directory, written by `HookDropWriter` with the file system's default permissions; the command sets none of its own.
- **Transmission**: none by this command; the drop file stays on the machine until a daemon reads it.
- **Retention**: this command never deletes a drop file; the daemon that scans the directory owns removal.
- **OAuth token**: the recovered token is used only as the argument to `accountName` and is not written into the envelope; the source does not otherwise redact the payload or the environment values it captures.


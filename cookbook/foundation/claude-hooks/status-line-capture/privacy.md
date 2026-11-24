
- **Data collected**: the status-line payload (which carries `rate_limits`, the session id and the working directory), the git-context fingerprint of the session's repository, the account name and OAuth login email from the injected closures, and the curated environment context `HookCaptureCommand.buildEnvelope` adds.
- **Storage**: a drop file in the configuration's drop directory, only when the daemon refuses the post; the lock file in the temporary directory holds no data.
- **Transmission**: the payload goes to the local daemon by the injected `post`; nothing leaves the machine from this component.
- **Retention**: a drop file stays until the daemon scans it in; this component does not delete it.
- **OAuth token**: the token is recovered from the `claude` process and carried to the detached feed in its environment, which a process listing by the same user can show for the life of the feed; it is not written to a file by this component, and the drop envelope carries only the account name derived from it.


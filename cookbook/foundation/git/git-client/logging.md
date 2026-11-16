
Subsystem/category are whatever this component's own logging
configuration assigns.

| Event | Level | Message shape |
|-------|-------|---------------|
| Every invocation attempt, regardless of outcome | info | `` `git [-c <key=value>]… <verb> <redacted-arguments> cwd=<path> from=<file>:<function> <ms>ms status=<exitStatus-or-"unfinished">` `` |

The command log MUST NOT log the process's standard output or standard
error to OSLog — only that a call happened and where it came from, so git
usage can be counted, attributed, and audited without the log becoming a
copy of the repository. The in-memory ring (`GitCommandLog.book`, see
command-log-ring) keeps a failed call's standard error, URL-redacted and
then truncated to 2048 bytes, for the Git window's Command Log; it is never
persisted and never written to OSLog. Arguments are logged at public visibility after passing through
the redaction rule (see Behavioral Requirements and Privacy above), never
collapsed as a whole, because that would hide the entire interpolation for
every verb rather than redacting the one argument position that needs it.
The redaction rule covers config values, the commit, tag and stash
messages, and any URL's user information (a token in a push URL logs as
`***`). Paths, branch, tag and remote names are logged as they are.


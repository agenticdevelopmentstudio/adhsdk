
### Spawning

- **spawn-result**: `spawn(executable:arguments:environment:stdin:)` MUST return true once the trampoline was started and false when nothing could be started (the pipe could not be made or the spawn failed).
- **spawn-trampoline**: The command MUST be started by a `/bin/sh -c` trampoline that backgrounds it and exits, with the executable and its arguments passed as positional parameters (`exe=$1; shift; "$exe" "$@"`) so no argument is ever re-parsed by the shell.
- **spawn-reparent**: By the time `spawn` returns the trampoline MUST have exited (it is awaited, retrying on an interrupted wait), so the command has no parent but launchd.
- **spawn-new-session**: The trampoline MUST be started in a new session so a signal to the caller's terminal process group does not reach the command.
- **spawn-environment**: The command MUST receive exactly the environment passed in, with no variable inherited from the caller.
- **spawn-output-discarded**: Standard output and standard error MUST go to the null device, and the command MUST NOT hold any descriptor of the caller's open, the dispatcher's stdout among them: only descriptors 0 to 3 cross into the child.
- **spawn-payload-fd3**: The payload MUST reach the command as its standard input through descriptor 3 (`<&3`) because an asynchronous list in a non-interactive shell gets the null device on descriptor 0 unless told otherwise, and descriptor 3 MUST be closed in the command after it is redirected.
- **spawn-payload-closed**: The write end of the payload pipe MUST be closed after the payload is written, so the command sees end of input, and the read end MUST be closed in the caller on every path.
- **spawn-failure-cleanup**: When the spawn fails the write end MUST be closed before returning false, leaking no descriptor.
- **spawn-payload-write-failure**: NEEDS REVIEW: Not implemented in source. An error thrown by the payload write is discarded with `try?` and `spawn` still returns true, so the caller is told the feed started when the command may have received a partial payload or none. Evidence that would settle it: whether any write error can occur while the caller itself holds the read end open, or whether a caller must learn of one.
- **spawn-nonexistent-command**: A command that does not exist MUST NOT make `spawn` fail or block: the trampoline starts, the background command fails inside the shell, and `spawn` returns true at once.
- **spawn-blocking**: `spawn` MUST block only for the payload write and the trampoline's exit, never for the command itself. The payload write blocks while the pipe is full and the command is not reading, and because the caller holds the read end open until `spawn` returns, a command that exits without reading never ends the write with a broken-pipe error; callers MUST NOT pass a payload larger than the command will read promptly.

### Feed lock

- **lock-file-name**: `FeedLock.fileURL(sessionID:name:directory:)` MUST be `<name>-statusline-feed-<session>.lock` under `directory`, defaulting to the temporary directory.
- **lock-session-sanitised**: The session id MUST be truncated to its first 128 unicode scalars and every scalar that is not an ASCII letter, digit or `-` MUST become `_`, so a session id can never escape the lock directory.
- **lock-acquire**: `acquire` MUST open the file read-write with creation, close-on-exec and mode `0600`, then take an exclusive non-blocking `flock`, and return the lock when it is taken.
- **lock-contended**: `acquire` MUST return nil, closing its descriptor, when another holder has the lock, and MUST NOT block.
- **lock-unguarded-fallback**: When the lock file cannot be opened (an unwritable or missing directory) `acquire` MUST return a no-op lock, not nil, so the feed runs unguarded rather than not at all.
- **lock-release**: `release()` MUST close the descriptor, which releases the `flock`, and MUST do nothing for a no-op lock.
- **lock-dies-with-process**: The lock MUST be tied to the descriptor, so a killed feed never leaves its session locked.
- **lock-per-session-per-name**: Two sessions whose sanitised, truncated ids differ, or two daemon names, MUST NOT contend with each other; two session ids that sanitise to the same text (`a/b` and `a_b`, or ids equal in their first 128 scalars) name one lock file and do contend.


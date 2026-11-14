
- Null and empty input: an empty payload is written as zero bytes and the command sees immediate end of input (MUST); an empty environment gives the command no variables (MUST); an executable path that is empty fails inside the shell and `spawn` still returns true (MUST).
- Malformed input: arguments holding spaces, quotes or `$` reach the command unchanged because they travel as positional parameters (MUST); an interior NUL in any string truncates it there (the strings are copied with `strdup`) and is not defended against.
- Boundary values: a session id of 128 scalars is kept whole, a longer one is truncated to 128 (MUST); a session id that is entirely non-ASCII becomes underscores (MUST).
- Concurrent access: two feeds for one session race on a non-blocking `flock`, exactly one wins and the loser skips (MUST); feeds for sessions whose sanitised ids differ never contend, while ids that sanitise to the same text share one lock (MUST).
- Error states: a failed `pipe` or `posix_spawn` returns false and closes its descriptors (MUST); a failed payload write is swallowed and `spawn` returns true, the gap marked in Behavioral Requirements.
- Interrupted wait: the wait for the trampoline retries on `EINTR` (MUST).
- Offline or disconnected state: not applicable; nothing here uses the network, though the command may.
- Lock file accumulation: `release()` only closes the descriptor and never unlinks the file, so one lock file per session stays in the lock directory; the source does no cleanup, so removal is left to the operating system's temporary-directory cleanup.
- Stale lock file: a lock file left on disk by a dead process is harmless because the lock is the `flock`, not the file's existence (MUST).


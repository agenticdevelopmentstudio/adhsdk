
**Decision**: `feedDeadline` bounds the whole feed at 20 seconds.
**Rationale**: Each step has its own timeout (5 seconds per `git` call, 2 seconds for the post), so the deadline is the outer bound that keeps feeds from piling up; it is a rationale, and the testable requirement is `feed-deadline`.
**Approved**: pending

**Decision**: Make `feedDeadline` injectable with 20 seconds as the default.
**Rationale**: `feedDeadline` is a fixed constant today, so the deadline vector needs a test that waits more than 20 seconds; an injected value would let it run in milliseconds.
**Approved**: pending

**Decision**: Carry the OAuth token to the detached feed on standard input instead of its environment, or accept the environment.
**Rationale**: A process listing by the same user (`ps -E`) can read the environment for the life of the feed; the source uses the environment today, which is why Token lifecycle is partial.
**Approved**: pending

**Decision**: The feed is run by a detached copy of the helper, and the render returns as soon as its line is printed.
**Rationale**: The source comment explains that the dispatcher kills a renderer still running after 3 seconds while a feed can take up to 17 seconds (three `git` watchdogs and the post); waiting for it threw the line away and killed the post. A detached process is out of the dispatcher's reach and bounded by its own deadline.
**Approved**: pending

**Decision**: The detach uses a `/bin/sh` trampoline that backgrounds the command and exits, with the process in its own session.
**Rationale**: The dispatcher kills a timed-out renderer by walking its descendants with `pgrep -P`, so a process reparented to launchd is out of that walk; leaving the session means a signal to the terminal's process group misses it too (the `DetachedProcess` comment).
**Approved**: pending

**Decision**: The feed runs in-process when this process is not the configuration's helper.
**Rationale**: The source comment names the in-process tests as the case; the helper-name check is also what stops a host that embeds the toolkit from spawning itself with a flag it does not understand.
**Approved**: pending

**Decision**: A new feed skips while the session's previous one runs.
**Rationale**: A render finds the next one carrying a newer snapshot anyway, so skipping loses nothing and stops feeds piling up behind a slow `git` call.
**Approved**: pending

**Decision**: The git fingerprint is taken inside the feed, before the post.
**Rationale**: The sample must be taken in the session's working directory at render time, and on the drop-file path ingest can be minutes later (the `feed` comment).
**Approved**: pending

**Decision**: The OAuth token is recovered by walking up the process tree and carried to a detached feed through its environment.
**Rationale**: Claude Code scrubs `CLAUDE_CODE_OAUTH_TOKEN`; the detached feed has been reparented, so it cannot walk to `claude` itself and receives the token its renderer recovered.
**Approved**: pending

**Decision**: `--capture-only` always exits 0.
**Rationale**: The status-line display can be switched off while Claude Code is still the only carrier of `rate_limits`, and a status line must never break Claude Code (the `captureOnlyFlag` comment).
**Approved**: pending

**Decision**: The feed lock degrades to a no-op when its file cannot be created.
**Rationale**: The `FeedLock` comment states the feed runs unguarded rather than not at all.
**Approved**: pending

**Decision**: A dropped envelope that cannot be written is lost without a signal.
**Rationale**: The source discards the write error with `try?` (a nil envelope is the deliberate headless guard, not a failure); a status line must never break Claude Code, and the next render sends a newer snapshot. The source states neither the rationale nor an alternative signal, so this is recorded here as the observed behavior.
**Approved**: pending


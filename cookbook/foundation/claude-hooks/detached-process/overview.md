
`DetachedProcess` starts a command that outlives the process that started it and is no one's child but launchd's. A `/bin/sh` trampoline starts the command in the background and exits at once, so by the time `spawn` returns the command has been reparented. The status-line dispatcher kills a timed-out renderer by walking its descendants; a process reparented this way is out of that walk's reach, and it leaves the caller's session too, so a signal to the terminal's process group misses it as well.

`FeedLock` is its companion. Claude Code re-renders the status line often, and a feed can take seconds, so each session gets one non-blocking `flock` lock: a render that finds the previous feed still running skips its own, and the next render carries the newer snapshot.


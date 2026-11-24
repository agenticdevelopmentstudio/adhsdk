
Process Liveness answers questions about the Claude Code CLI (`claude`) processes running for the current user, with no subprocess: it reads the process table through libproc and sysctl. It is a case-less namespace (`ProcessLiveness`) in the core framework.

It answers these questions:

1. Which `claude` processes are alive, in which directory were they launched, which session is each running, and what is each one's parent (`liveClaudeProcesses()`). A session reconciler uses this: a session is active while its `claude` process exists and ended when it does not.
2. Which session does one pid run, read from the CLI's own session file (`currentSessionId(ofPid:environment:)`, `sessionId(fromSessionFile:pid:)`).
3. Which single live `claude` is in a given directory, refusing to guess when there are two (`claudePid(inCwd:)`, `uniqueClaude(among:inCwd:directory:isClaude:canonical:)`). An `http` hook carries only the payload, whose `cwd` locates the process whose environment is then read.
4. Whether a `claude` is a headless scripted run and whether it has a controlling terminal (`isHeadless(argv:sessionFile:)`, `terminalAttachment(ofPid:)`).
5. A real-path form of a path (`canonicalPath(_:)`).

Identity comes from the launched executable path, not from `proc_pidpath`. The source records why: the CLI's real image is a version-named binary (`~/.local/share/claude/versions/2.1.183`, whose basename is the version) and `proc_pidpath` fails outright once an update removes an old version's file. The launch path is recorded at exec time, so it is stable and present for every process, and the desktop app (`/Applications/Claude.app`) has a different launch path, so it is left out.


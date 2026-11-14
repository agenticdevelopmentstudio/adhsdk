
Process Env reads facts about other running processes from the kernel: the arguments and environment a process was started with, its parent pid, and the names it answers to. On top of that it does three jobs for hook and status-line helpers.

1. It recovers `CLAUDE_CODE_OAUTH_TOKEN` from a parent `claude` process. Claude Code scrubs the token from the environment it gives hook and status-line commands, but the token is still in the `claude` process's own launch environment, which a same-user process can read.
2. It finds the pid of the `claude` process that ran a hook, from the hook's own parent pid, checking names rather than trusting position.
3. It remembers recovered tokens per pid for 30 seconds, in a bounded cache, so a daemon that asks on every event does not walk the process table each time.

It lives in the core framework so the daemons and the command-line tools all link one copy. It is a case-less namespace (`ProcessEnv`).


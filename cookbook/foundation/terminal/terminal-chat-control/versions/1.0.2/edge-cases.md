
- **Empty or missing input**: a nil `chat` resolves only when exactly one chat exists; an empty-string `chat` matches every id as a prefix, so it behaves like nil and fails when several chats exist.
- **Ambiguous prefix**: a prefix that matches several chats MUST fail and list the matching ids rather than pick one.
- **Case**: chat ids compare ignoring case and the query is lowercased in the not-found message.
- **No chats**: `list` returns an empty `chats` array, and every other action fails with `There is no Terminal Chat open.` when no query is given.
- **Chat without a terminal**: a chat that exists but is not connected is listed with `connected` false and refuses `run`, `wait`, `interrupt` and `screen`.
- **Missing command**: `run` with a nil or empty `command` fails with `run needs a command.`.
- **Out-of-range timing**: a `settle` or `timeout` of zero or a negative number clamps to 0.1 seconds and a value above the maximum clamps down to it; the request is never rejected for this.
- **Screen line count**: a `lines` below 1 is raised to 1 by the chat session's `screen`.
- **Command that outlasts the wait**: `run` returns what it has when the timeout passes and reports the command as still running; the client MUST use `wait` for more.
- **Stale sockets**: a socket whose process has exited is skipped by `runningHosts` and removed by `prepareSocketDirectory`; a pid reused by another process can look running, and the connection then fails.
- **Other user's process**: `kill(pid, 0)` failing with `EPERM` still counts as running.
- **Stalled host**: a host that never answers holds only its own call, when the caller passes a short `wait`.
- **Malformed request or reply**: the host answers `Not a Terminal Chat request.` and the client throws on an undecodable reply.
- **Concurrent access**: one request per connection; the chat session ends a previous wait with what it had when a new one starts, so two clients driving the same chat can cut each other's wait short.
- **Error and offline states**: with the app not running, no socket is live and the client finds no host.
- **Oversized request**: a request longer than the socket server's 1 MiB limit is dropped unanswered, so the client's call fails.
- **Different user**: the socket server closes a connection whose peer user id is not its own, so another user's client gets no reply.
- **Shutdown**: a request that arrives as the host is shutting down is answered `The app is shutting down.`.


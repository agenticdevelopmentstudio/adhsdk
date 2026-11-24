
No test covers `TerminalChatControl` itself; `TerminalChatSessionTests` covers the session behind it. The vectors below follow from the source's logic. They are written against `resolve`, `Defaults`, the socket helpers and the codable shapes, which need no running app.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-chat-control-001 | resolve-only-chat | `resolve(nil, in: [one chat])` | success with that chat |
| terminal-chat-control-002 | resolve-none | `resolve(nil, in: [])` | failure `There is no Terminal Chat open.` |
| terminal-chat-control-003 | resolve-prefix | chats `a1b2c3d4` and `f9e8d7c6`; `resolve("A1B", in: both)` | success with `a1b2c3d4`, the prefix compared ignoring case |
| terminal-chat-control-004 | resolve-none | `resolve("zz", in: both)` | failure `No Terminal Chat with id zz.` |
| terminal-chat-control-005 | resolve-many | chats `a1b2c3d4` and `a1ffffff`; `resolve("a1", in: both)` | failure `More than one Terminal Chat matches — choose one of: a1b2c3d4, a1ffffff` |
| terminal-chat-control-006 | resolve-many | `resolve(nil, in: both)` | the same many-match failure, listing both ids |
| terminal-chat-control-007 | default-timeout-for-action | `Defaults.timeout(for: .interrupt)`, then for `.run`, `.wait`, `.screen` and `.list` | 10, then 60 for each of the others |
| terminal-chat-control-008 | default-settle, default-lines, default-maximums | the `Defaults` constants | 1.5, 40, 60 and 600 |
| terminal-chat-control-009 | request-init-defaults, request-fields | `Request(action: .list)` encoded and decoded | an equal request, with every optional field nil |
| terminal-chat-control-010 | action-values | `Action.interrupt.rawValue`, and decoding `"screen"` | `interrupt`, and `.screen` |
| terminal-chat-control-011 | response-failure, response-success | `Response.failure("x")` | `error` is `x`, `isSuccess` false, every other field nil |
| terminal-chat-control-012 | response-success | `Response(output: "ok")` | `isSuccess` true |
| terminal-chat-control-013 | socket-url | `socketURL(pid: 4242, in: dir)` | `dir/4242.sock` |
| terminal-chat-control-014 | prepare-owner-only | `prepareSocketDirectory(tmp)` on a missing directory | the directory exists with permissions 0700 |
| terminal-chat-control-015 | running-hosts, running-hosts-skip-names | a directory holding `<own pid>.sock`, `notes.txt` and `abc.sock`; `runningHosts(in:)` | one host, the current process |
| terminal-chat-control-016 | prepare-removes-stale | a directory holding `<pid of an exited process>.sock`; `prepareSocketDirectory(dir)` | the socket file is gone |
| terminal-chat-control-017 | running-hosts, running-hosts-missing-directory | `runningHosts(in:)` on a directory that does not exist | an empty list |
| terminal-chat-control-018 | running-hosts | sockets for two running pids | both hosts, the lower pid first |
| terminal-chat-control-019 | send-wait-margin | `send` of a `run` with `timeout` 30 against a host that answers after 40 seconds, `wait` not given | a decoded reply, because the wait is 45 seconds |
| terminal-chat-control-020 | send-errors | `send` to a socket path where nothing listens | throws |
| terminal-chat-control-021 | resolve-error-type | `resolve("zz", in: [])` | a failure whose `ResolveError.message` is `No Terminal Chat with id zz.`, equal to another `ResolveError` with the same message |
| terminal-chat-control-022 | prepare-error | `prepareSocketDirectory` on a path whose parent is a regular file | throws |
| terminal-chat-control-023 | running-test | `runningHosts(in:)` for a directory holding a socket named for pid 1 | pid 1 is listed, because `kill(1, 0)` fails with `EPERM` for a non-root user and that still counts as running |
| terminal-chat-control-024 | request-chat-field | `resolve("", in: [two chats])` | the many-match failure, because an empty string is a prefix of every id |
| terminal-chat-control-025 | response-init-defaults | `Response(output: "ok")` | every field but `output` is nil |

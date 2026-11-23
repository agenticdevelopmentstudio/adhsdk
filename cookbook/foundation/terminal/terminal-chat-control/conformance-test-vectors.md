
`TerminalChatControlConformanceTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Terminal/`) covers every vector below; `TerminalChatSessionTests` covers the session behind it. The vectors are written against `resolve`, `Defaults` and the codable shapes, which need no running app. The numbers 013 to 020, 022 and 023 belonged to the socket helpers and the client call, which are gone, and are not reused.

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
| terminal-chat-control-021 | resolve-error-type | `resolve("zz", in: [])` | a failure whose `ResolveError.message` is `No Terminal Chat with id zz.`, equal to another `ResolveError` with the same message |
| terminal-chat-control-024 | request-chat-field | `resolve("", in: [two chats])` | the many-match failure, because an empty string is a prefix of every id |
| terminal-chat-control-025 | response-init-defaults | `Response(output: "ok")` | every field but `output` is nil |

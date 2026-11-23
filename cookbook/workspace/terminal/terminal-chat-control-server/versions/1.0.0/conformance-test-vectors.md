
The repository has no test that names these types. The vectors are derived from the source; the directory holds sessions that are test doubles, and a request is the JSON line a client sends.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-chat-control-server-001 | chat-id | Node UUID `ABCDEF12-3456-7890-ABCD-EF1234567890` | `abcdef12`. |
| terminal-chat-control-server-002 | directory-add, chats-sorted | Add chats (project "b", pane 1), (project "a", pane 2), (project "a", pane 1) | Listing order: ("a", 1), ("a", 2), ("b", 1). |
| terminal-chat-control-server-003 | directory-add | Add two sessions under the same id | One chat, the second session. |
| terminal-chat-control-server-004 | directory-remove | Remove an id, then an unknown id | The chat is gone; the unknown id does nothing. |
| terminal-chat-control-server-005 | directory-weak | Add a session, release it, list | The listing is empty. |
| terminal-chat-control-server-006 | chats-presentable, chats-connected | A private session with a terminal and words mike to robin; project "mike" | The chat lists project "robin" and `connected` true. |
| terminal-chat-control-server-007 | chats-presentable, chats-connected | A session with no terminal | The chat lists its text as given with `connected` false. |
| terminal-chat-control-server-008 | list-action | `{"action":"list"}` | A response with every chat and the app name. |
| terminal-chat-control-server-009 | answer-decode-failure, answer-app-name | The line `not json` | `{"error":"Not a Terminal Chat request."}` with no app name; a decodable request that fails (for example run with no command) carries `"app":"<appName>"`. |
| terminal-chat-control-server-010 | resolve-chat | `{"action":"screen"}` with no chats; with two chats; with a chat id prefix that matches one | "There is no Terminal Chat open."; "More than one Terminal Chat matches — choose one of: …"; the one chat is served. |
| terminal-chat-control-server-011 | not-connected | `{"action":"run","chat":"ab","command":"ls"}` for a chat without a terminal | The error naming the chat id and Connect to Terminal. |
| terminal-chat-control-server-012 | run-needs-command | `{"action":"run"}` and `{"action":"run","command":""}` on a connected chat | "run needs a command." for each; nothing typed. |
| terminal-chat-control-server-013 | run-action, through-chat | `{"action":"run","command":"ls"}` | The session's run is called with `ls`; the answer carries the chat id and its output. |
| terminal-chat-control-server-014 | settle-clamp | `settle` 0.01, 1000 and absent | 100 ms, 60000 ms and 1500 ms. |
| terminal-chat-control-server-015 | timeout-clamp | `timeout` absent for run and for interrupt; 9999 | 60000 ms for run, 10000 ms for interrupt, 600000 ms for 9999. |
| terminal-chat-control-server-016 | wait-action, interrupt-action | A wait and an interrupt request | The session's wait and interrupt-and-wait are called; each answer carries the chat id and output. |
| terminal-chat-control-server-017 | screen-action | A screen request with no `lines`; with `lines` 5; for a session with no screen | 40 lines asked; 5 lines asked; output "". |
| terminal-chat-control-server-018 | server-start, server-start-idempotent | `start()` twice | One listener at `<socketDirectory>/<pid>.sock`. |
| terminal-chat-control-server-019 | server-start-error | The socket directory cannot be created | `start()` throws and no server is kept; a later `start()` tries again. |
| terminal-chat-control-server-020 | server-stop | `stop()` before and after `start()` | No error either time; the socket file is gone after the second. |
| terminal-chat-control-server-021 | answer-shutting-down | The server object is released while a request is in flight | `{"error":"The app is shutting down."}`. |
| terminal-chat-control-server-022 | socket-owner-only, request-size-cap, one-request-per-connection | Check the socket file mode; connect as another user; send 2 MiB; send two lines | Mode 0600 in a 0700 directory; the peer is refused; no answer; the first line is answered and the connection closes. |
| terminal-chat-control-server-023 | concealed-reply | A chat on a private terminal replies with its screen | The answer holds the alias, never the real text. |


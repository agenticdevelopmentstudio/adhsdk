
`TerminalChatDirectoryToolSourceTests` drives the tool source over a fake listing of fake chats; the directory's vectors are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-chat-control-server-001 | chat-id | Node UUID `ABCDEF12-3456-7890-ABCD-EF1234567890` | `abcdef12`. |
| terminal-chat-control-server-002 | directory-add, chats-sorted | Add chats (project "b", pane 1), (project "a", pane 2), (project "a", pane 1) | Listing order: ("a", 1), ("a", 2), ("b", 1). |
| terminal-chat-control-server-003 | directory-add | Add two sessions under the same id | One chat, the second session. |
| terminal-chat-control-server-004 | directory-remove | Remove an id, then an unknown id | The chat is gone; the unknown id does nothing. |
| terminal-chat-control-server-005 | directory-weak | Add a session, release it, list | The listing is empty. |
| terminal-chat-control-server-006 | chats-presentable, chats-connected | A private session with a terminal and words mike to robin; project "mike" | The chat lists project "robin" and `connected` true. |
| terminal-chat-control-server-007 | chats-presentable, chats-connected | A session with no terminal | The chat lists its text as given with `connected` false. |
| terminal-chat-control-server-008 | five-tools | `toolDefinitions()` | The names list, run, wait, interrupt, screen. |
| terminal-chat-control-server-009 | list-action | `list` with `{}` | A JSON array of every chat; not an error. |
| terminal-chat-control-server-010 | resolve-chat | `screen` with a prefix matching one chat; matching two; matching none; no chat with one open; no chat with two open | The one chat is served; "More than one Terminal Chat matches — choose one of: …"; "No Terminal Chat with id <prefix>."; the only chat is served; an error. |
| terminal-chat-control-server-011 | not-connected | `run` `{"chat":"ab","command":"ls"}` for a chat without a terminal | The error naming the chat id and Connect to Terminal. |
| terminal-chat-control-server-012 | run-needs-command | `run` with `{}` on a connected chat | "run needs a command." as an error; nothing typed. |
| terminal-chat-control-server-013 | run-action, through-chat | `run` `{"command":"ls"}` | The chat's run is called with `ls`; the answer is its output. |
| terminal-chat-control-server-014 | settle-clamp, timeout-clamp | `run` with no timings; with settle 0.01 and timeout 9999 | 1500 ms and 60000 ms; 100 ms and 600000 ms. |
| terminal-chat-control-server-015 | interrupt-default-timings, interrupt-action | `interrupt` with settle 9 and timeout 9 | The chat's interrupt-and-wait is called with 1500 ms and 10000 ms. |
| terminal-chat-control-server-016 | screen-action | `screen` with no `lines`; with `lines` 5; for a chat with no screen | 40 lines asked; 5 lines asked; output "". |
| terminal-chat-control-server-017 | unknown-tool | A call to `type` | "Unknown tool type." as an error. |
| terminal-chat-control-server-018 | concealed-reply | A chat on a private terminal replies with its screen | The answer holds the alias, never the real text. |

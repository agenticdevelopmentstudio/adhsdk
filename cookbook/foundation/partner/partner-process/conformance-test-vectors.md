
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-process-001 | start-launches, decode-each-line, send-user-message, stream-ends-with-process, terminate, is-running | Process of `/bin/cat` with no arguments and an empty environment; `start()`; check `isRunning`; read `messages()` in a task; `send("x")`; wait 300 ms; `terminate()`. | `isRunning` is true after start and false after terminate; the stream finishes within 10 seconds; the first message has kind `user` and its first block text is `x` (test: catEchoDecodesAndTerminateEndsTheStream). |
| partner-process-002 | single-consumer | A started process; call `messages()` once and discard, then iterate the second call's stream. | The second stream yields 0 messages and finishes (test: secondMessagesCallReturnsAFinishedStream). |
| partner-process-003 | undecodable-skipped, stream-ends-with-process | Process of `/bin/echo` with the argument `not json`; `start()`; iterate `messages()`. | 0 messages and the stream finishes (test: undecodableLinesAreSkipped). |
| partner-process-004 | decode-each-line | Process of `/bin/echo` with the argument `{"type":"result","subtype":"success","is_error":false,"result":"ok","session_id":"s"}`; `start()`; iterate. | One message of kind `result` with `resultText` `ok` (test: resultLineDecodes). |
| partner-process-005 | send-before-start | A process never started; `send("x")`. | Throws a not-launched error. |
| partner-process-006 | start-once | A started process; call `start()` again. | Throws an already-launched error. |
| partner-process-007 | start-launches | Executable path that does not exist; `start()`. | Throws the channel's launch failure. |
| partner-process-008 | terminate-unstarted | A process never started; `terminate()`. | Returns without error; `isRunning` is false. |
| partner-process-009 | stderr-text | A started process of `/bin/sh` that writes `boom` to stderr and exits; after the stream ends call `standardErrorText()`. | The text contains `boom`. |


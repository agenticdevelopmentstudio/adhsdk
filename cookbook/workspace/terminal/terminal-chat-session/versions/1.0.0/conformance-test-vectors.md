
The vectors that name a test are from `TerminalChatSessionTests`, which drives a real `/bin/sh` through a connected terminal session. The rest are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-chat-session-001 | run-reply, wait-timeout, output-report-latency (testOutputThatNeverPausesStillReachesTheRun) | Run `while true; do echo tick; sleep 0.1; done` with settle 1.5 s and timeout 3 s | The reply contains "tick" and ends with the still-running line. |
| terminal-chat-session-002 | wait-settle-cap (testASettleLongerThanTheTimeoutStillReportsAFinishedCommand) | Run `echo done` with settle 30 s and timeout 4 s | The reply contains "done" and not the still-running line. |
| terminal-chat-session-003 | interrupt-wait, wait-timeout (testInterruptWaitsAsLongAsItIsTold) | Interrupt a process that ignores Control-C with settle 0.5 s and timeout 2 s | The reply ends with the still-running line, after less than 5 s. |
| terminal-chat-session-004 | unclaimed-keep, wait-replay, run-fresh (testOutputAfterARunGaveUpGoesToWaitNotToTheNextRun) | Run `sleep 1; echo late-one` with timeout 0.6 s, wait 2 s, then wait for output; then the same with late-two followed by a run of `echo next` | The first wait returns "late-one"; the next run returns "next" and not "late-two". |
| terminal-chat-session-005 | exit-handling (testAShellThatExitsLetsGoAtOnce) | Run `exit` with timeout 30 s | The reply ends with the shell-exited text, in under 10 s; the chat's terminal is nil and the terminal is no longer running. |
| terminal-chat-session-006 | send-return-separate (testReturnArrivesAsAWriteOfItsOwn) | Run a program that reads two raw chunks, then send "hello" | The program sees `hello` then `\r` as two chunks. |
| terminal-chat-session-007 | run-armed-late (testAShortSettleStillGetsTheCommandsOutput) | Run `echo $((40+2))QQ` with settle 50 ms | The reply contains "42QQ" and the next wait does not. |
| terminal-chat-session-008 | send-order (testQuickSendsKeepTheirOrder) | Send "one" then "two" to a program reading raw input until two Returns | It reads `one\rtwo\r`. |
| terminal-chat-session-009 | send-closes-target, close (testAMessageSentJustBeforeClosingStillRuns) | Send `echo closed$((1+1))` then close at once | The terminal's screen shows `closed2`. |
| terminal-chat-session-010 | run-armed-late (testATimeoutShorterThanTheReturnDelayStillGetsTheOutput) | Run `echo $((6*7))ZZ` with timeout 400 ms | The reply contains "42ZZ" and not the still-running line. |
| terminal-chat-session-011 | run-not-connected, screen-not-connected, send-not-connected | A session with no terminal: run, wait, interrupt, screen, send | The not-connected text for the three waits; nil for screen; a turn failure "Not connected to a terminal." for send. |
| terminal-chat-session-012 | initial-state, unsent-events | Produce a reply (connect to a terminal showing a prompt) before subscribing, then subscribe | First event is ready, then the held started, delta and finished events. A message sent before subscribing is not among them. |
| terminal-chat-session-013 | screen-lines | A screen with 3 text rows then blank rows; `lines` 2, 0 | The last two text rows; with 0, the last one row. |
| terminal-chat-session-014 | wait-timeout, wait-empty | A wait on a terminal that prints nothing, with timeout 2 s | After 2 s, "(no output)" followed by the still-running line. |
| terminal-chat-session-015 | unclaimed-dropped-marker | More than 64 KiB of unclaimed replies then a wait | The reply starts with "[… earlier output dropped]". |
| terminal-chat-session-016 | connect-initial-output, connect-replace | Connect to a terminal showing a prompt | A started, delta and finished event with the prompt text, and no waiting caller receives it. |
| terminal-chat-session-017 | interrupt | Send a message, interrupt before its Return | Control-C is written and no Return follows. |


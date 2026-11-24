
Vectors come from `ConversationSummaryDTOTests` (Core test target) and the source's own logic; vectors 022 to 031 are the `testV022_` to `testV031_` tests in the same file.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| conversation-summary-dto-001 | status-from-session-derive | active session, `lastEventType` `Stop` (`testStatusFollowsTheTurn`) | `idle` |
| conversation-summary-dto-002 | status-from-session-derive | active, `PreToolUse` | `busy` |
| conversation-summary-dto-003 | status-from-session-derive | active, `PermissionRequest` | `waiting` |
| conversation-summary-dto-004 | status-from-session-derive | active, `Stop`, `subagentWorking` true | `busy` |
| conversation-summary-dto-005 | status-from-session-ended | `status` `ended`, `lastEventType` `Stop` | `ended` |
| conversation-summary-dto-006 | home-relative-prefix | `/Users/me/src` against home `/Users/me` (`testHomeRelative`) | `~/src` |
| conversation-summary-dto-007 | home-relative-equal, home-relative-trailing-slash | `/Users/me` against `/Users/me/` | `~` |
| conversation-summary-dto-008 | home-relative-sibling | `/Users/meow` against `/Users/me` | `/Users/meow` |
| conversation-summary-dto-009 | home-relative-empty-home | `/tmp` against `` | `/tmp` |
| conversation-summary-dto-010 | summary-cwd, summary-session-name, agent-always-claude, summary-last-activity | session with cwd `/Users/me/src/app`, title `my chat`, last activity `2026-11-10 10:00:00`, home `/Users/me` (`testSummaryReadsTheSession`) | cwd `~/src/app`, sessionName `my chat`, agent `claude`, lastActivity equals `UTCTimestamp.canonical("2026-11-10 10:00:00")` |
| conversation-summary-dto-011 | matches-prefix | app `claude`, `ITERM`, `ghostty` against an `iTerm.app` session (`testAppMatchesAgentOrTerminalByPrefix`) | true, true, false |
| conversation-summary-dto-012 | matches-empty | app `` against any session | true |
| conversation-summary-dto-013 | work-in-progress, base-branches | branches `main`, `master`, ``, `HEAD`, then `fix-login` (`testWorkInProgressIsAFeatureBranchOrAWorktree`) | false for the four base branches, true for `fix-login` |
| conversation-summary-dto-014 | in-worktree, work-in-progress | cwd `/Users/me/src/app/.claude/worktrees/wt/Sources` on `main` | true |
| conversation-summary-dto-015 | in-worktree-bare | cwd `/Users/me/src/app/.claude/worktrees` on `main` | false |
| conversation-summary-dto-016 | info-can-send, refusal-ended, refusal-terminal | info for a live `iTerm.app` session, an ended one, and a `vscode` one (`testInfoCanSendOnlyToALiveSupportedTerminal`) | `canSend` true, false, false |
| conversation-summary-dto-017 | refusal-waiting, info-send-refusal, refusal-busy-idle | `PermissionRequest` session (`testWaitingConversationRefusesASend`) | `canSend` false and `sendRefusal` contains `waiting on a prompt`; a `PreToolUse` session gives nil; a healthy session's `sendRefusal` is `` |
| conversation-summary-dto-018 | refusal-pane-sharer | parent, child and other sessions, parent and child in pane `P` (`testSessionsSharingAPaneRefuseASend`) | child and parent `canSend` false; child's refusal names `parent`; the session in pane `Q` `canSend` true |
| conversation-summary-dto-019 | refusal-sharer-active-only | the parent with an ended child in the same pane | `canSend` true |
| conversation-summary-dto-020 | refusal-sharer-excused, refusal-detached | a probe saying only `worker` is `detached`, parent and worker in one pane (`testAHeadlessSharerWithNoTerminalLeavesThePaneToTheInteractiveSession`) | refusal for parent nil; refusal for worker contains `headless` |
| conversation-summary-dto-021 | refusal-sharer-unknown | a probe that always returns nil, same sessions | refusal for parent is non-nil |
| conversation-summary-dto-022 | refusal-ended | `refusal` for an ended session `s1` | `conversation s1 has ended.` |
| conversation-summary-dto-023 | summary-last-activity | `lastActivityAt` of `not a date` | `lastActivity` equals `not a date` |
| conversation-summary-dto-024 | refusal-order | an ended session in an unsupported terminal (`vscode`) | the refusal is `conversation <id> has ended.`, not the terminal sentence (derived from the source order; no test) |
| conversation-summary-dto-025 | refusal-terminal | a live session with `termProgram` `` | `typing into a conversation needs iTerm2 or Terminal.app; <id> runs in an unknown terminal.` (derived from the source; no test) |
| conversation-summary-dto-026 | refusal-no-pane | two live sessions whose pane does not resolve | neither is refused for sharing a pane (derived from the source; no test) |
| conversation-summary-dto-027 | terminal-name, summary-terminal | `termProgram` `iTerm.app`, then `ghostty` | `iTerm2`, then `ghostty` (derived from `KnownTerminals`; no test) |
| conversation-summary-dto-028 | matches-ignores-empty-names | app `x` against a session with an empty `termProgram` | the empty name does not match (derived from the source; no test) |
| conversation-summary-dto-029 | info-raw-fields, info-project-root, info-started-at | an info built from a session with `projectRoot` `/Users/me/src/app`, `startedAt` `2026-11-10 10:00:00`, home `/Users/me` | `projectRoot` `~/src/app`, `startedAt` equals `UTCTimestamp.canonical("2026-11-10 10:00:00")`, and `termProgram`, `model`, `lastTool`, `summary`, `pid` equal the session's (derived from the source; no test) |
| conversation-summary-dto-030 | process-attachment | a session whose recorded `pid` exceeds the `pid_t` range | the probe is asked about the clamped value (derived from `pid_t(clamping:)`; no test) |
| conversation-summary-dto-031 | summary-home-default | a summary built without `homeDirectory` | paths are rewritten against `NSHomeDirectory()` (derived from the source default; no test) |

---
id: e74bbbe4-cc41-40dc-a063-e262522c2301
title: "Conversation Summary DTOs"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A conversation read from a session: status, list row, info record, app matching, work-in-progress rules, and when a message may be typed into its pane."
platforms:
  - swift
  - macos
tags:
  - stenographer
  - foundation
  - dto
  - wire
depends-on:
  - 25b6559b-69c1-450f-85b3-fc026d55f469
related: []
references: []
approved-by: ""
approved-date: ""
---

# Conversation Summary DTOs

## Overview

A conversation is a live terminal session in which a person is talking to an agent. These types present the daemon's `SessionDTO` (see Session DTOs ([adhsdk.ingredient.foundation.stenographer.session-dt-os](cookbook:25b6559b-69c1-450f-85b3-fc026d55f469))) in the shape a conversation reader needs: `ConversationAgent` (the agent name), `ConversationStatus` (busy, idle, waiting, ended), `ConversationSummaryDTO` (one row of `steno conversations list`), `ConversationInfoDTO` (the row plus the rest of what the daemon knows, for `steno conversation info`) and `ConversationSendability` (the one answer `steno conversation send` acts on and `info`'s `canSend` reports). The session is the conversation; these types add no storage. Every session the daemon records is a Claude Code session, so the agent is stated as a field (`claude`) so that a second agent is a new value and not a new shape.

## Behavioral Requirements

- **agent-constant**: `ConversationAgent.claude` MUST be the string `claude`.
- **agent-always-claude**: `ConversationSummaryDTO.agent` and `ConversationInfoDTO.agent` MUST be `ConversationAgent.claude` for every session.
- **status-cases**: `ConversationStatus` MUST have exactly the cases `busy`, `idle`, `waiting` and `ended`, with the raw values equal to the case names.
- **status-busy**: `busy` MUST mean the agent is mid-turn, or a subagent is, so that a message sent now queues.
- **status-idle**: `idle` MUST mean the session is alive with nothing in flight and the agent at its prompt.
- **status-waiting**: `waiting` MUST mean the agent is blocked on the person, such as a permission prompt or a question.
- **status-ended**: `ended` MUST mean the session's process is gone.
- **status-from-session-ended**: `ConversationStatus.init(session:)` MUST yield `ended` when `session.status` is not the raw value of `SessionStatus.active`, whatever the last event.
- **status-from-session-derive**: For an active session, `ConversationStatus.init(session:)` MUST derive the status with `SessionActivity.derive` from `lastEventType` and `subagentWorking`, mapping `working` to `busy`, `idle` to `idle` and `waiting` to `waiting`.
- **summary-fields**: A `ConversationSummaryDTO` MUST carry `id`, `agent`, `terminal`, `cwd`, `sessionName`, `gitBranch`, `lastActivity` (all String) and `status` (`ConversationStatus`).
- **summary-id**: `id` MUST be the session id, the id every `steno conversation` verb takes.
- **summary-terminal**: `terminal` MUST be the terminal's name from `KnownTerminals` for the session's `termProgram` (for example `iTerm2`), else the raw `termProgram`.
- **summary-cwd**: `cwd` MUST be the session's working directory written `~`-relative when it is under the home directory.
- **summary-session-name**: `sessionName` MUST be the session's `transcriptTitle`, and MUST be an empty string, never nil, when the session is unnamed.
- **summary-git-branch**: `gitBranch` MUST be the session's `gitBranch` unchanged, and MUST be an empty string, never nil, when the session is not in a repository.
- **summary-last-activity**: `lastActivity` MUST be `UTCTimestamp.canonical` of the session's `lastActivityAt`, and MUST fall back to the raw `lastActivityAt` when that does not parse.
- **summary-home-default**: `ConversationSummaryDTO.init(session:homeDirectory:)` MUST default `homeDirectory` to `NSHomeDirectory()`.
- **home-relative-equal**: `homeRelative(_:homeDirectory:)` MUST return `~` when the path equals the home directory.
- **home-relative-prefix**: `homeRelative` MUST return `~` followed by the rest of the path when the path starts with the home directory and a slash.
- **home-relative-trailing-slash**: `homeRelative` MUST ignore one trailing slash on the home directory.
- **home-relative-sibling**: `homeRelative` MUST NOT rewrite a path that merely shares the home directory's characters as a prefix, such as `/Users/meow` against `/Users/me`.
- **home-relative-empty-home**: `homeRelative` MUST return the path unchanged when the home directory is empty.
- **terminal-name**: `terminalName(_:)` MUST return the known terminal's `displayName` for a recognised `TERM_PROGRAM`, else the raw value.
- **matches-empty**: `matches(app:session:)` MUST return true when `app` is empty.
- **matches-prefix**: `matches(app:session:)` MUST return true when the lowercased `app` is a prefix of the lowercased agent name `claude`, of the session's `termProgram`, or of the known terminal's `displayName`.
- **matches-ignores-empty-names**: `matches(app:session:)` MUST NOT match against an empty name.
- **base-branches**: `baseBranches` MUST be the set of the empty string, `main`, `master` and `HEAD`, where `HEAD` is what a detached checkout reports.
- **work-in-progress**: `isWorkInProgress(session:)` MUST be true when the session's `gitBranch` is not in `baseBranches`, or when its `cwd` is inside a worktree.
- **in-worktree**: `isInWorktree(_:)` MUST be true when the path has a `.claude` segment immediately followed by a `worktrees` segment and then at least one more segment, at any depth.
- **in-worktree-bare**: `isInWorktree(_:)` MUST be false for a path that ends at `.claude/worktrees` with no worktree name after it.
- **info-fields**: A `ConversationInfoDTO` MUST carry `id`, `agent`, `terminal`, `termProgram`, `cwd`, `projectRoot`, `sessionName`, `gitBranch`, `model`, `startedAt`, `lastActivity`, `status`, `lastEvent`, `lastTool`, `summary`, `pid`, `canSend` and `sendRefusal`.
- **info-from-summary**: `ConversationInfoDTO.init` MUST take `id`, `agent`, `terminal`, `cwd`, `sessionName`, `gitBranch`, `lastActivity` and `status` from the `ConversationSummaryDTO` built from the same session.
- **info-raw-fields**: `ConversationInfoDTO.init` MUST copy `termProgram`, `model`, `lastTool`, `summary` and `pid` from the session, and `lastEvent` from the session's `lastEventType`.
- **info-project-root**: `projectRoot` MUST be the session's `projectRoot` written `~`-relative, and MUST be an empty string when the session has no `projectRoot`.
- **info-started-at**: `startedAt` MUST be `UTCTimestamp.canonical` of the session's `startedAt`, falling back to the raw value when it does not parse.
- **info-can-send**: `canSend` MUST be true exactly when `ConversationSendability.refusal` returns nil.
- **info-send-refusal**: `sendRefusal` MUST be the refusal sentence, and MUST be an empty string when `canSend` is true.
- **info-live-sessions**: `ConversationInfoDTO.init` MUST take the active sessions as `liveSessions`, which the pane-sharing check reads.
- **info-attachment-probe**: `ConversationInfoDTO.init` MUST take an `attachment` probe that defaults to `ConversationSendability.processAttachment`, so a test can inject the answer.
- **refusal-ended**: `refusal` MUST return exactly `conversation <id> has ended.` for an `ended` conversation.
- **refusal-waiting**: `refusal` MUST refuse a `waiting` conversation with exactly `conversation <id> is waiting on a prompt (a permission or a question); answer it in its terminal. A message typed now would land in the prompt, and its Return would pick the highlighted choice.`, because its pane holds a permission or question prompt and the Return that follows typed text would pick the highlighted choice.
- **refusal-order**: `refusal` MUST test in this order: ended, waiting, unsupported terminal, detached process, pane sharer; the first match wins.
- **refusal-terminal**: `refusal` MUST refuse a session whose terminal `TerminalTextInjector.isSupported` rejects, with exactly `typing into a conversation needs iTerm2 or Terminal.app; <id> runs in <termProgram>.`, where `<termProgram>` is `an unknown terminal` when it is empty.
- **refusal-detached**: `refusal` MUST refuse a session whose process the probe reports as `detached`, with exactly `conversation <id> is a headless claude (claude -p, run by a script or shell), which reads its prompt once and never a terminal, so nothing typed into a pane can reach it.`
- **refusal-pane-sharer**: `refusal` MUST refuse a session when another active session's pane resolves to the same `TerminalTextInjector.Target`, with exactly `conversation <sharer id> runs in the same terminal pane as <id> (a nested or headless claude shares its parent's), so a message can't be aimed at <id> alone.`
- **refusal-sharer-excused**: A pane sharer whose probe reports `detached` MUST NOT block the session.
- **refusal-sharer-unknown**: A pane sharer whose probe returns nil MUST still block the session, because an unreadable process might be on the pane.
- **refusal-sharer-active-only**: A sharer whose `status` is not the raw value of `SessionStatus.active` MUST NOT block the session.
- **refusal-busy-idle**: `refusal` MUST return nil for a `busy` or `idle` conversation that passes the later checks, so a busy conversation's message queues.
- **refusal-no-pane**: `refusal` MUST NOT run the pane-sharer check for a session whose pane does not resolve.
- **attachment-probe-type**: `AttachmentProbe` MUST be a `@Sendable` function from `SessionDTO` to an optional `ProcessLiveness.TerminalAttachment`, where nil means the process cannot be read.
- **process-attachment**: `processAttachment` MUST ask `ProcessLiveness.terminalAttachment(ofPid:)` for the session's recorded `pid`, clamped into `pid_t`.
- **conformance-protocols**: `ConversationSummaryDTO` and `ConversationInfoDTO` MUST be `Codable`, `Sendable` and `Equatable`; `ConversationStatus` MUST be `String`, `Codable`, `Sendable` and `CaseIterable`.

## Appearance

Not applicable — this is a set of data shapes and a pure decision rule, not a visual component.

## States

Not applicable — this is a set of data shapes and a pure decision rule, not a visual component.

## Accessibility

Not applicable — this is a set of data shapes and a pure decision rule, not a visual component.

## Conformance Test Vectors

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
## Edge Cases

- **Unparsable timestamps**: a `lastActivityAt` or `startedAt` that `UTCTimestamp.canonical` rejects MUST pass through unchanged; no error is raised.
- **Unknown terminal**: an empty or unrecognised `TERM_PROGRAM` yields the raw value as `terminal`; for send it is refused with `an unknown terminal` when empty.
- **Unnamed session**: `sessionName` and `gitBranch` are empty strings for a session with no title or repo (see **summary-session-name** and **summary-git-branch**).
- **Home directory of `/`**: dropping its one trailing slash leaves an empty home, so `homeRelative` returns the path unchanged.
- **Path equal to home with a trailing slash in the path**: only the home directory's trailing slash is stripped; a path `/Users/me/` against `/Users/me` starts with the home and a slash, so it returns `~/`.
- **Detached checkout**: `HEAD` is a base branch, so a detached checkout outside a worktree is not work in progress.
- **Process cannot be read**: the probe returns nil; the session itself is not refused for it, but as a sharer it blocks the other session.
- **Session with pid 0**: `processAttachment` passes it to `ProcessLiveness.terminalAttachment(ofPid:)`, which answers nil for any pid that is not above 0 or whose process is not a Claude Code CLI process, without reading its terminal (`testTerminalAttachmentIsUnknownForAProcessThatIsNotClaude`).
- **Concurrent access**: the DTOs are immutable `Sendable` values and `ConversationSendability` has no state; the probe is `@Sendable`. The sharer check reads a snapshot of `liveSessions` taken by the caller, so a session that starts after the snapshot is not seen. The source defines no ordering beyond that.
- **Offline and error states**: no network is used; the only outside read is the process probe, and its failure is nil, which this code treats as unknown, never as an error.
- **Unrecognised last event**: `SessionActivity` reads an empty `lastEventType`, `Stop`, `StopFailure`, `Interrupted`, `SessionStart` and `SessionEnd` as idle, `Notification`, `PermissionRequest` and `Elicitation` as waiting, and every other value as working, so an active session whose last event is unknown reads as `busy`.
- **Mid-turn and subagent**: a live subagent reads as `busy` even when the main turn's last event is `Stop`, except that it never overrides `waiting`; that precedence is `SessionActivity.derive`'s.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| homeDirectory | String | `NSHomeDirectory()` | Home used to write paths `~`-relative. |
| liveSessions | array of `SessionDTO` | none (caller supplies) | Active sessions the pane-sharer check reads. |
| attachment | `AttachmentProbe` | `ConversationSendability.processAttachment` | Reports whether a session's process has a terminal; nil when unreadable. |


`baseBranches` is a fixed constant (see **base-branches**), not an option.
## Deep Linking

Not applicable: these shapes define no URL or deep link.

## Localization

The refusal sentences and `ConversationAgent.claude` are hardcoded English and are returned as user-facing text by `steno conversation send` and `info`; there is no string table.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: working directories, project roots, session names, git branches, model, pid and the summarizer's line about what the session is doing.
- **Storage**: none here; the daemon owns the session record.
- **Transmission**: values go from the daemon to `steno` and the app on the local machine; this code opens no connection.
- **Retention**: none defined by this code.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: A conversation picker lists `ConversationSummaryDTO` rows and disables its send control from `ConversationInfoDTO.canSend`, showing `sendRefusal` as the reason.
- **Compose**: Kotlin data classes with `kotlinx.serialization`; model `ConversationStatus` as an enum class with `@SerialName` lowercase values and the refusal decision as a pure function over a session snapshot and a probe lambda.
- **React/Web**: TypeScript string-literal union for status; the refusal logic is a pure function taking a live-sessions array and an injected probe; `homeRelative` needs the home directory passed in because a browser has none.
- **AppKit / UIKit**: The types are UI-agnostic; the Swift implementation depends on `SessionDTO`, `SessionActivity`, `KnownTerminals`, `UTCTimestamp`, `TerminalTextInjector` and `ProcessLiveness`, uses `NSHomeDirectory()` and `pid_t(clamping:)`, and declares `AttachmentProbe` as a `@Sendable` typealias.
- **WinUI 3**: Use C# records with `System.Text.Json` (`JsonStringEnumConverter` with a lowercase naming policy for `ConversationStatus`), a static class for the sendability rule, a `Func<SessionDto, TerminalAttachment?>` for the probe, `Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)` for the home directory, `Path.DirectorySeparatorChar` splitting for the worktree check, and `Process.GetProcessById` plus a Win32 console query in place of the Darwin process probe; the pane is a Windows Terminal or console host, so `TerminalTextInjector` has no direct equivalent and the terminal check needs its own support list.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/ConversationSummaryDTO.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The agent is a field fixed to `claude` rather than assumed.
**Rationale**: The source states every recorded session is a Claude Code session because Claude Code's hooks record it, and a field means a second agent is a new value and not a new shape.
**Approved**: pending

**Decision**: A `waiting` conversation is refused for send, not just an `ended` one.
**Rationale**: The source states the pane holds a permission or question prompt that ignores typed letters and takes the Return as picking its highlighted choice, approving a tool nobody approved.
**Approved**: pending

**Decision**: A session whose pane another live session also resolves to is refused, and so is the other.
**Rationale**: The source states a headless or nested `claude` inherits its parent's `TERM_SESSION_ID` and TTY, nothing recorded tells the two apart, so neither is sent to while both are live.
**Approved**: pending

**Decision**: A sharer confirmed to have no controlling terminal does not block, while one whose process cannot be read still does; the detached session is itself refused.
**Rationale**: The source states a headless `claude -p` reads a pipe so typing cannot reach it and the pane is the interactive session's alone; only a confirmed `detached` is excused.
**Approved**: pending

**Decision**: Work in progress is a feature branch or a worktree path, with `main`, `master`, `HEAD` and empty as base branches.
**Rationale**: The source defines it as a session on a feature branch or inside a `.claude/worktrees/<name>` directory; a path ending at `worktrees` with no name is not a worktree.
**Approved**: pending


**Decision**: Refusal sentences are English text built in the type, not reason codes.
**Rationale**: The only callers are the `steno conversation send` and `info` verbs, which print the sentence as is, so a code-to-text mapping would add a layer nothing needs yet; a second audience would call for returning a code.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.user-safety.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | partial | User Safety |

separation-of-concerns passes: the file maps a session to a conversation reading and decides send eligibility; storage, transport and the terminal injection itself are other types. unit-test-coverage passes: `ConversationSummaryDTOTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Stenographer/ConversationSummaryDTOTests.swift`) covers every vector, 001 to 031. safe-defaults is partial: an ended, waiting, unsupported-terminal, detached or pane-sharing session refuses a send, and a sharer whose process cannot be read blocks, but a session whose own process cannot be read (the probe returns nil) is not refused for that reason.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ConversationSummaryDTOTests.swift, 31 of 31 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Gave full refusal sentences, rewrote RFC 2119 wording, folded empty-string rules into named requirements, added eight vectors and a localization decision, and made safe-defaults partial. |

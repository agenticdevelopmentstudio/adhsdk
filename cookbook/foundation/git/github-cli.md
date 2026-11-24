---
id: b7e2c4d1-8f3a-4c6e-a1d9-2e5f7b0c3d84
title: "GitHub CLI"
type: ingredient
version: 1.0.1
status: draft
language: en
created: 2026-11-16
modified: 2026-11-16
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Pull requests through the user's own gh: availability, list, a branch's pull request, checkout and create, with a fixed environment, error mapping, budgets and redacted command logging."
platforms:
  - swift
  - macos
tags:
  - git
  - github
  - pull-requests
  - subprocess
  - logging
depends-on:
  - 5d0f6a3e-2b8c-4e71-9a4d-7c3e1f9b2a60
related:
  - 779ac6ea-9ef5-4fb0-8ed9-dc6b9d617344
references:
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitHubCLI.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitPullRequest.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitCommandLog.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# GitHub CLI

## Overview

A client for the GitHub CLI, `gh`, that answers pull request questions for the repository a directory belongs to: whether pull requests can be shown at all, the list, the pull request of a branch, checking one out and creating one. `gh` is the user's own tool, logged in by the user; the client never stores a token, never reads `gh`'s configuration and never chooses a host. `GitHubCLI` is an actor with an injected runner and an `ExecutableLocator`, and it is the only place that spawns `gh`. Every call is recorded in the git command log with `tool` `gh`.

## Behavioral Requirements

- **single-spawn-point**: `gh` MUST be spawned only through `GitHubCLI`'s one run step, through its runner.
- **locate-before-spawn**: The run step MUST find `gh` with its `ExecutableLocator`; when none is found it MUST throw (or answer) `notInstalled` without calling the runner, and MUST still record the call with no exit status.
- **fixed-environment**: Every child MUST be given `GH_PROMPT_DISABLED=1`, `NO_COLOR=1` and `GH_NO_UPDATE_NOTIFIER=1`, and `PATH` set to the locator's search directories joined by `:`. The client MUST NOT set `GH_TOKEN` and MUST NOT pass `--hostname`.
- **no-credentials**: The client MUST NOT store a token and MUST NOT read `gh`'s configuration files.
- **availability-command**: `availability(in:)` MUST run `gh repo view --json url` and answer the decoded `url`, or the mapped error, as a `Result`; it MUST NOT throw.
- **list-command**: `pullRequests(in:state:limit:)` MUST run `gh pr list --state <state> --limit <limit> --json number,title,state,isDraft,author,headRefName,baseRefName,url,updatedAt,statusCheckRollup,reviewDecision,isCrossRepository`, with defaults `open` and `50`.
- **view-command**: `pullRequest(forBranch:in:)` MUST run `gh pr list --head <branch> --state all --limit 20 --json <the same fields>,headRepositoryOwner`, MUST drop every row whose `isCrossRepository` is true (`--head` matches the branch name in forks too), and MUST answer the open pull request among the rest if there is one, else the one updated most recently, else nil. It MUST NOT use `gh pr view <branch>`, which reads a branch named like a number or URL as that pull request. An empty or dash-led branch MUST be refused as `failed` before anything runs.
- **checkout-command**: `checkout(_:in:)` MUST run `gh pr checkout <number>`; a number below 1 MUST be refused as `failed` before anything runs.
- **create-command**: `create(title:body:base:head:draft:in:)` MUST run `gh pr create --title <title> --body <body>`, then `--base <base>` when `base` is non-empty, then `--head <head>` when `head` is given, then `--draft` when `draft`; an empty or dash-led `head` MUST be refused as `failed("not a branch name: <head>")` before anything runs; it MUST answer the last `http`/`https` URL line of standard output, and `failed` when there is none.
- **budgets**: Reads (`repo view`, `pr list`) MUST run under a 10-second budget; `pr checkout` and `pr create` under 60 seconds.
- **error-mapping**: A non-zero exit MUST map by standard error, case-insensitively, testing not-GitHub first (gh's not-GitHub message itself suggests `gh auth login`): containing `none of the git remotes`, `not a github`, `no git remotes found` or `no default remote repository` → `notGitHub`; containing `gh auth login` or `not logged` → `notAuthenticated`; anything else → `failed(<standard error, trimmed>)`. A runner that exceeds its budget → `timedOut`. A cancellation MUST propagate unchanged. Any other runner error, or output that does not decode → `failed`.
- **pull-request-model**: A pull request MUST carry `number`, `title`, `state` (`OPEN`, `CLOSED`, `MERGED`), `isDraft`, `author` (the login), `headRefName`, `baseRefName`, `url`, `updatedAt` (ISO 8601, with or without fractional seconds), `checks` and `reviewDecision`; its identity is its number. An empty `reviewDecision` MUST decode as nil.
- **check-rollup**: `checks` MUST be nil for an empty or missing `statusCheckRollup`, and otherwise count each entry once: a `CheckRun` is pending until its status is `COMPLETED`, then passing for conclusion `SUCCESS`, `NEUTRAL` or `SKIPPED`, pending for an empty conclusion or `STALE` (a result about an earlier head), and failing for any other; a `StatusContext` is passing for `SUCCESS`, failing for `FAILURE` or `ERROR`, and pending otherwise.
- **logged-as-gh**: Every call MUST be recorded in the command log with tool `gh`, verb the first argument, the remaining arguments, the directory, the caller, the duration, the exit status (none when nothing ran or the run did not finish) and, for a non-zero exit, standard error.
- **text-redacted**: The log MUST redact the argument after `--title`, `--body`, `-t` and `-b` of a `gh` call as `<redacted:<length>>`; the git rules do not apply to `gh`, and the URL user-info rule applies to every argument.

## Appearance

Not applicable: `GitHubCLI` presents no UI. A missing `gh`, or one that is not logged in, hides the Pull Requests section rather than showing an error.

## States

Not applicable: the actor holds only its locator, runner and command log; every call is independent.

## Accessibility

Not applicable: `GitHubCLI` presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| github-cli-001 | fixed-environment | `availability(in:)` with a stub runner | the runner sees `GH_PROMPT_DISABLED=1`, `NO_COLOR=1`, `GH_NO_UPDATE_NOTIFIER=1` and no `GH_TOKEN` (test: environmentHoldsTheThreeVariables). |
| github-cli-002 | availability-command, budgets | stdout `{"url":"https://github.com/o/r"}` | `.success(https://github.com/o/r)`; arguments `repo view --json url`; 10 s (test: availabilityArgumentsAndAnswer). |
| github-cli-003 | list-command, budgets | `pullRequests(in:)`, then `state: "all", limit: 5` | `pr list --state open --limit 50 --json <fields>`, then `--state all --limit 5`; 10 s (test: pullRequestsArguments). |
| github-cli-004 | view-command | `pullRequest(forBranch: "feature/login")` | `pr list --head feature/login --state all --limit 20 --json <fields>,headRepositoryOwner` (test: pullRequestForBranchArguments). |
| github-cli-005 | checkout-command, budgets | `checkout(42)` | `pr checkout 42`; 60 s (test: checkoutArguments). |
| github-cli-006 | create-command, budgets | `create` without base, then with base `develop` and draft; stdout ends in `https://github.com/o/r/pull/43` | `pr create --title … --body …`, then `… --base develop --draft`; the URL; 60 s (test: createArgumentsAndPrintedURL). |
| github-cli-007 | pull-request-model, check-rollup | a recorded two-pull-request list | #42 with checks 2 passing, 1 failing, 2 pending and `APPROVED`; #41 draft with no checks and no review decision (test: decodesARecordedTwoPullRequestList). |
| github-cli-008 | check-rollup | one `StatusContext` with state `ERROR` | 0 passing, 1 failing, 0 pending (test: pullRequestForBranchDecodesOne). |
| github-cli-009 | error-mapping | stdout `not json` | `failed` (test: unreadableOutputIsFailed). |
| github-cli-010 | error-mapping | stderr containing `gh auth login`, or `NOT LOGGED` | `notAuthenticated` (tests: notLoggedInIsNotAuthenticated, notLoggedIntoHostIsNotAuthenticated). |
| github-cli-011 | error-mapping | gh's whole `none of the git remotes … To tell gh about a new GitHub host, please use `gh auth login``, or `Not a GitHub repository` | `notGitHub`, not `notAuthenticated` (tests: noGitHubRemoteIsNotGitHub, notAGitHubRepositoryIsNotGitHub). |
| github-cli-012 | error-mapping | the runner throws a budget-exceeded error | `timedOut` (test: budgetExceededIsTimedOut). |
| github-cli-013 | error-mapping | stderr `HTTP 502: Bad Gateway (…)` with a trailing newline | `failed` with the trimmed text (test: anythingElseIsFailedWithStandardError). |
| github-cli-014 | view-command | `pr list --head` answers `[]` | nil (test: noPullRequestForBranchIsNil). |
| github-cli-015 | locate-before-spawn | no `gh` on any search directory | `notInstalled`, the runner never called, two entries with no exit status (test: missingBinaryIsNotInstalledWithoutSpawning). |
| github-cli-016 | logged-as-gh | a successful `pr list` | an entry with tool `gh`, arguments `pr list …`, the directory, status 0 and the explicit caller passed (test: entriesAreLoggedWithToolGh). |
| github-cli-017 | logged-as-gh | a failed `repo view`, status 4 | the entry keeps the standard error (test: failedEntryKeepsStandardError). |
| github-cli-018 | text-redacted | `create(title: "Secret title", body: "token abc", base: "main", draft: true)` | logged as `pr create --title <redacted:12> --body <redacted:9> --base main --draft` (test: createTitleAndBodyAreRedactedInTheLog). |
| github-cli-019 | text-redacted | gh `pr view -m`; git `commit --title x` | both unchanged (test: ghRedactionLeavesGitRulesAlone). |
| github-cli-020 | create-command | `create` with base `main`, head `parser` and draft | `pr create --title … --body … --base main --head parser --draft` (test: createPassesTheHeadBranch). |
| github-cli-021 | create-command, input-sanitization | `create` with head `` and with head `-x` | `failed("not a branch name: <head>")`; nothing runs (test: createRefusesAHeadThatIsNotABranchName). |
| github-cli-020 | view-command | `pullRequest(forBranch: \"4521\")` | `pr list --head 4521 --state all --limit 20 --json …`, never `pr view 4521` (test: numericBranchNameIsLookedUpAsAHead). |
| github-cli-021 | error-mapping | stderr `no git remotes found`; stderr `No default remote repository has been set. …` | `notGitHub` (tests: noRemotesIsNotGitHub, noDefaultRemoteIsNotGitHub). |
| github-cli-022 | view-command | branch `main`: a stranger's newest open fork PR #90, this repository's merged #80 and older open #70 | #70: the fork row dropped, open preferred over newer (test: forkPullRequestWithTheSameBranchNameIsSkipped). |
| github-cli-023 | view-command | only a fork PR with the branch's name | nil (test: onlyForkPullRequestsIsNil). |
| github-cli-024 | view-command | closed #5 (Nov 1) and merged #6 (Nov 10), none open | #6 (test: withNoOpenPullRequestTheNewestWins). |

## Edge Cases

- **Null / empty input**: An empty branch is refused before anything runs. An empty `base` is treated as no base. An empty body is passed as `--body ""`, so `gh` does not open an editor.
- **Boundary values**: A `limit` below 1 is sent as 1. A pull request number below 1 is refused.
- **Malformed input**: A dash-led branch is refused so it cannot be read as a flag. A branch named like a number or URL is still looked up as a head branch. A pull request from a fork whose branch has the same name is not this branch's, and is skipped; so, knowingly, is the user's own pull request opened from their fork (a triangular workflow), which `headRepositoryOwner` is fetched to support later. Output that does not decode is `failed`, never a partial list.
- **Concurrent access**: `GitHubCLI` is an actor, and each call suspends while `gh` runs, so calls do not serialise behind one another.
- **Error states**: See **error-mapping**. A missing `gh` and a `gh` that is not logged in are not errors to show: the caller hides what depends on them.
- **Offline / disconnected state**: `gh` reports the network failure on standard error, which maps to `failed`; a hung network ends at the budget as `timedOut`.
- **Cancellation and timeouts**: A cancelled task's cancellation propagates unchanged and the call is recorded with no exit status; a budget overrun terminates the child and is `timedOut`.

## Configuration

None: no settings key. The locator (default: the process environment and the default extra directories) and the runner (default: a one-shot subprocess run that merges the environment over the app's own) are injected.

## Deep Linking

Not applicable: no URL scheme or route. The pull request URL it answers is the caller's to open.

## Localization

Not applicable: no user-facing string; `failed` carries `gh`'s own text.

## Accessibility Options

Not applicable: no UI.

## Feature Flags

Not applicable: no feature flag.

## Analytics

Not applicable: no analytics call.

## Privacy

- **Data handled**: Pull request metadata from GitHub, and a title and body the user typed for a new pull request.
- **Storage**: None; nothing is persisted. No token is stored or read; authentication is `gh`'s own.
- **Transmission**: `gh` talks to the host it is logged in to; the client adds no host and no credential.
- **Retention**: The command log's in-memory ring keeps the redacted command line and, for a failed call, the first 2 KB of standard error with URL user info redacted, for the life of the process.

## Logging

| Event | Level | Message shape |
|-------|-------|---------------|
| Every `gh` call, including one that found no `gh` | info | `` `gh <verb> <redacted-arguments> cwd=<path> from=<file>:<function> <ms>ms status=<exitStatus-or-"unfinished">` `` |

Recorded through the git command log, so the line and the in-memory entry follow its rules: no standard output anywhere, standard error only in the in-memory ring and only for a non-zero exit. The title and body of `pr create` are redacted (**text-redacted**).

## Platform Notes

- **SwiftUI**: `Core/Git/GitHubCLI.swift` and `Core/Git/GitPullRequest.swift` import only Foundation. `GitHubCLI` is a `public actor`; a SwiftUI caller drives it from a cancellable task and treats `CancellationError` as its own.
- **AppKit / UIKit**: Identical to the SwiftUI note. The runner type is `@Sendable (URL, [String], URL, [String: String], Duration) async throws -> SubprocessChannel.RunResult`; the default runs `SubprocessChannel.run` with `.mergeOverParent` and the budget in seconds. A budget overrun arrives as `WallClockBudgetExceeded`. `GitPullRequest` is `Sendable, Hashable, Identifiable, Decodable`, decoding the date itself with `Date.ISO8601FormatStyle`, so it needs no decoder strategy.
- **Compose**: A class with a suspend function per verb over an injected `ProcessBuilder` runner and `kotlinx.serialization` models; the budget is `withTimeout`.
- **React/Web**: Not applicable in a browser (no process). In Node, `child_process.execFile` with `env` and `timeout`, and `JSON.parse` of standard output.
- **WinUI 3**: `Process` with `RedirectStandardOutput`/`RedirectStandardError`, the three variables in `Environment`, and `System.Text.Json` models.

## Design Decisions

**Decision**: Use the user's `gh` and its login rather than a token of the app's own.
**Rationale**: The user already trusts `gh` with their GitHub account; holding a second credential would add storage, refresh and revocation the app has no reason to own.
**Approved**: pending

**Decision**: Map errors by standard error text and exit status.
**Rationale**: `gh` reports a missing login and a non-GitHub repository with exit status 1 or 4 and a sentence, not a distinct code; matching a few stable phrases case-insensitively separates the two outcomes the UI hides from the ones it reports.
**Approved**: pending

**Decision**: Record `gh` calls in the git command log.
**Rationale**: The Git window's Command Log is where a user asks "what did the app run"; a second log for `gh` would split the answer.
**Approved**: pending

**Decision**: The runner is injected.
**Rationale**: Tests must never reach the network or a real GitHub; a stub runner with recorded `--json` output exercises arguments, environment, decoding and error mapping without spawning anything.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |

`separation-of-concerns` passes because the client only runs `gh` and decodes its answers; finding the executable is `ExecutableLocator`'s and recording is the command log's. `unit-test-coverage` passes: `GitHubCLITests` (`Tests/AgenticDeveloperHubSDKCoreTests/Git/GitHubCLITests.swift`) covers all 21 vectors with a stub runner. `input-sanitization` passes because a dash-led or empty branch and a non-positive number are refused before anything runs, and arguments are passed as an argument vector, never through a shell.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-16 | Mike Fullerton | Initial creation |
| 1.0.1 | 2026-11-16 | Mike Fullerton | Phase 4 final review: `create` passes `--head` and refuses a head that is not a branch name (vectors 020-021); a STALE check is pending. |

---
id: 294285ac-403a-44fe-9840-8ad9f3cf1eba
title: "Partner Job Defaults"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The jobs every install starts with: the built-in code-reviews job with its ids, 30-minute timer, guidelines text and three steps, plus the retired general job's id."
platforms:
  - swift
  - macos
tags:
  - partner
  - job
  - defaults
  - code-review
depends-on:
  - 79810488-c613-4f9b-af2a-4ba9d8ee1c26
related:
  - 211ef664-01fc-45d5-996b-1a0a4167a748
  - 2a298bb0-d8af-40aa-8fec-42dd3b1d8f43
references: []
approved-by: ""
approved-date: ""
---

# Partner Job Defaults

## Overview

`PartnerJobDefaults` is a case-less enumeration that holds the built-in partner jobs. Today there is one: the code-reviews job, a loop in which the app crawls repositories and queues commits before each timer tick, and the partner starts reviews, drives each review session through three steps (open a session, run a review, fix the findings) and judges what each session's screen says. The enumeration supplies the job's ids, its guidelines text, its steps and its default timer, and exposes the list of all built-in jobs (`all`) that the app seeds into the store when a built-in job is missing. It also keeps the id of the retired "general" job, only so the guidelines installer can remove what that job left behind. The jobs are `PartnerJob` values; their shape is specified by Partner Job ([adhsdk.ingredient.foundation.partner.partner-job](cookbook:79810488-c613-4f9b-af2a-4ba9d8ee1c26)), and the placeholders in their commands are filled by Partner Step Template ([adhsdk.ingredient.foundation.partner.partner-step-template](cookbook:211ef664-01fc-45d5-996b-1a0a4167a748)).

## Behavioral Requirements

Identifiers

- **code-reviews-id**: `codeReviewsID` MUST be the string `code-reviews`.
- **retired-general-id**: `retiredGeneralID` MUST be the string `general`; it MUST NOT name a job in `all`, and exists only so `PartnerGuidelinesInstaller` can remove the retired job's store row, job file and skill.

The built-in list

- **all-contents**: `all` MUST contain exactly one job, the code-reviews job, and MUST NOT contain the retired general job.
- **all-fresh-values**: `all` and `codeReviews()` MUST build a new value on each call, so a caller that mutates the result does not change the defaults.
- **defaults-reproducible**: Two calls to `codeReviews()` MUST return equal values, so a stored job can be compared with, or reset to, its default.

The code-reviews job (`codeReviews()`)

- **job-identity**: The job MUST have id `code-reviews` and name `Code reviews`.
- **job-disabled-by-default**: The job MUST have `isEnabled` false, so a fresh install does nothing until the owner turns it on.
- **job-schedule**: The job MUST have `scheduleSeconds` 1800 (thirty minutes).
- **job-built-in**: The job MUST have `isBuiltIn` true.
- **job-guidelines**: The job's `guidelines` MUST be the text of `codeReviewsGuidelines`.
- **job-steps**: The job MUST have exactly three steps, in this order: `open session`, `review`, `fix`.

The steps

- **step-open-session**: The first step MUST have name `open session`, environment `terminal`, command `claude --model {model} --dangerously-skip-permissions`, and condition `A fresh tab in the review worktree.` The command passes `--dangerously-skip-permissions` so the review session runs without permission prompts; this is a deliberate trust decision recorded in Design Decisions.
- **step-review**: The second step MUST have name `review`, environment `claude`, command `/code-review high {sha}`, and condition `Claude Code is at its prompt; no review already running in this repo.`
- **step-fix-command-exact**: The fix step's command MUST equal the text under "Exact fix command" below character for character; the four requirements that follow it describe parts of that text.
- **step-fix-name**: The third step MUST have name `fix`, environment `claude`, and condition `The review has finished.`
- **step-fix-skips-superseded**: The fix step's command MUST tell Claude to fix every finding that still applies at the tip, and to skip findings whose code the later commits (the `{superseded}` placeholder) already changed or removed, saying which.
- **step-fix-commit**: The fix step's command MUST tell Claude to commit on the `{fix_branch}` placeholder with the trailer `"Reviewed-Commit: {sha}"` (quotes included).
- **step-fix-no-push**: The fix step's command MUST say `Do not push` and that the fixes stay on the fix branch for the owner to merge.
- **step-fix-report**: The fix step's command MUST ask Claude to report what was fixed and what was skipped.
- **step-placeholders**: The commands MUST use these placeholders and no others: `{model}`, `{sha}`, `{fix_branch}` and `{superseded}`; they are filled by `PartnerStepTemplate` when a review is started, not here.

The guidelines text (`codeReviewsGuidelines`)

- **guidelines-exact**: `codeReviewsGuidelines` MUST equal the text under "Exact guidelines text" below character for character, with a blank line between paragraphs; the requirements that follow describe parts of that text.
- **guidelines-tick**: The text MUST tell the partner that, on a tick, the message says how many reviews are queued and running, and to call `partner_review_next` and then start reviews with `partner_review_start`, oldest first, while `running` is below `concurrency`.
- **guidelines-one-per-repo**: The text MUST tell the partner never to start two reviews in one repo, and, when a start says the repo's review worktree needs the owner, to leave that review queued and start no other review of that repo and branch in that tick.
- **guidelines-skipped-start**: The text MUST tell the partner that a `partner_review_start` result that is skipped (no session, no steps) needs nothing more, because the app has already marked it.
- **guidelines-run-steps**: The text MUST tell the partner to run the listed steps in order in the named session, using `partner_session_run` for both terminal commands and Claude prompt text (typed at Claude Code's prompt), and to check each step's condition on the screen before typing it.
- **guidelines-range-fallback**: The text MUST tell the partner that, if the review step's `/code-review` rejects the bare sha as its target, it types the command again with the range `{sha}^..{sha}` in the sha's place.
- **guidelines-idle-event**: The text MUST tell the partner, on a session idle event for a review session, to read the screen with `partner_session_screen` and decide among four outcomes: still working (end the turn), step finished (type the next step), last step finished (call `partner_review_finish` with `done` and a one-paragraph summary of the findings fixed, the findings skipped and why), or stuck or waiting on something it cannot answer (raise an attention item).
- **guidelines-answer-prompts**: The text MUST tell the partner to answer what Claude Code asks along the way, the trust-this-folder prompt included.
- **guidelines-exit-event**: The text MUST tell the partner, on a session exited event for a review session that is not finished, to call `partner_review_finish` with `failed` and what the screen last showed.
- **guidelines-wait-limit**: The text MUST tell the partner never to wait on `partner_session_wait` longer than its maximum, but to end the turn and let the idle event wake it.
- **guidelines-no-push**: The text MUST say nothing is pushed and the fixes stay on the fix branch for the owner to merge.
- **guidelines-tool-names**: The text MUST name the tools `partner_review_next`, `partner_review_start`, `partner_review_finish`, `partner_session_run`, `partner_session_screen` and `partner_session_wait`; these names are the partner's tool contract with the app's MCP endpoint.

Concurrency and side effects

- **pure-constants**: Every member MUST be a pure, constant or freshly built value with no I/O, no clock read and no shared mutable state, so it is safe from any thread.


**Exact guidelines text**

```
On a tick, the message says how many reviews are queued and running. Call `partner_review_next`, then start reviews with `partner_review_start`, oldest first, while `running` is below `concurrency`. Never start two reviews in one repo. When a start says the repo's review worktree needs the owner, the review stays queued and the owner has been told: start no other review of that repo and branch this tick.

A `partner_review_start` result that is skipped (no session, no steps) needs nothing more: the app has already marked it. Otherwise it names the review's session and lists its steps with their placeholders filled. Run them in order in that session: a terminal step's command with `partner_session_run`, and a claude step's prompt text with `partner_session_run` too, typed at Claude Code's prompt. Check each step's condition on the screen before typing it. If the review step's `/code-review` rejects the bare sha as its target, type it again with the range `{sha}^..{sha}` in the sha's place.

On a session idle event for a review session, read its screen with `partner_session_screen` and decide: the current step is still working (end your turn), it finished (type the next step), the last step finished (call `partner_review_finish` with `done` and a one-paragraph summary of the findings fixed and the findings skipped, and why), or it is stuck or waiting on something you cannot answer (raise an attention item). Answer what Claude Code asks on the way, the trust-this-folder prompt included.

On a session exited event for a review session that is not finished, call `partner_review_finish` with `failed` and what the screen last showed.

Never wait on `partner_session_wait` longer than its maximum; end your turn and let the idle event wake you. Nothing is pushed: the fixes stay on the fix branch for the owner to merge.
```

**Exact fix command**

```
Fix every finding that still applies at the tip. Skip findings whose code the later commits ({superseded}) already changed or removed, and say which. Commit on {fix_branch} with the trailer "Reviewed-Commit: {sha}". Do not push: the fixes stay on {fix_branch} for the owner to merge. Report what was fixed and what was skipped.
```
## Appearance

Not applicable — this is a namespace of default job data, not a visual component.

## States

Not applicable — this is a stateless constants namespace, not a visual component. The job it builds starts disabled; whether it is later enabled is the owner's setting, held in the store.

## Accessibility

Not applicable — this is a namespace of default job data, not a visual component.

## Conformance Test Vectors

Vectors 001 to 004 are asserted in `PartnerModelsTests` (001), `CodeReviewsSchedulerTests` (002, 003) and `PartnerJobsEditorModelTests` (004); the rest are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-job-defaults-001 | all-contents, job-steps | `PartnerJobDefaults.all.map(\.id)` and `codeReviews().steps.map(\.name)` (`defaultsHaveTheTwoBuiltInJobs`) | Ids are exactly `code-reviews`; step names are `open session`, `review`, `fix` |
| partner-job-defaults-002 | step-fix-commit, step-fix-no-push | Read `codeReviews().steps[2].command` (`testTheFixStepCommitsOnTheFixBranchAndNeverPushes`) | Contains `Commit on {fix_branch}`, `Do not push` and `"Reviewed-Commit: {sha}"` |
| partner-job-defaults-003 | guidelines-tool-names, guidelines-range-fallback, guidelines-wait-limit | Read `codeReviews().guidelines` (`testTheGuidelinesNameTheLoopAndTheRangeFallback`) | Contains `partner_review_next`, `partner_review_start`, `partner_review_finish`, `partner_session_run`, `partner_session_wait` and `{sha}^..{sha}` |
| partner-job-defaults-004 | job-guidelines, job-steps, defaults-reproducible | Edit a stored default job, reset it, compare to `codeReviews()` (`testResetToDefaultRestoresStepsAndDeletesGuidelinesFile`) | Reset steps equal the default steps (3 steps); reset guidelines equal the default guidelines |
| partner-job-defaults-005 | code-reviews-id, retired-general-id | Read `codeReviewsID` and `retiredGeneralID` | `code-reviews` and `general` |
| partner-job-defaults-006 | all-contents, retired-general-id | `all.contains { $0.id == "general" }` | false |
| partner-job-defaults-007 | job-identity, job-disabled-by-default, job-schedule, job-built-in | Read the fields of `codeReviews()` | Id `code-reviews`, name `Code reviews`, `isEnabled` false, `scheduleSeconds` 1800, `isBuiltIn` true |
| partner-job-defaults-008 | step-open-session | Read steps[0] | Environment `terminal`, command `claude --model {model} --dangerously-skip-permissions`, condition `A fresh tab in the review worktree.` |
| partner-job-defaults-009 | step-review | Read steps[1] | Environment `claude`, command `/code-review high {sha}`, condition `Claude Code is at its prompt; no review already running in this repo.` |
| partner-job-defaults-010 | step-fix-name, step-fix-skips-superseded, step-fix-report | Read steps[2] | Environment `claude`, condition `The review has finished.`; command contains `{superseded}` and `Report what was fixed and what was skipped.` |
| partner-job-defaults-011 | step-placeholders | Collect every brace-wrapped word across the three commands | The set is `model`, `sha`, `fix_branch`, `superseded` |
| partner-job-defaults-012 | job-guidelines | Compare `codeReviews().guidelines` with `codeReviewsGuidelines` | Equal |
| partner-job-defaults-013 | all-fresh-values, defaults-reproducible | Mutate the `isEnabled` of one `codeReviews()` result, then call it again | The second call has `isEnabled` false; two untouched calls are equal |
| partner-job-defaults-014 | guidelines-tick, guidelines-one-per-repo, guidelines-skipped-start | Read the guidelines | Contains `while \`running\` is below \`concurrency\``, `Never start two reviews in one repo` and `skipped (no session, no steps)` |
| partner-job-defaults-015 | guidelines-idle-event, guidelines-exit-event, guidelines-no-push | Read the guidelines | Contains "partner_review_finish" followed by "with `done`", the sentence beginning "On a session exited event for a review session that is not finished", and "Nothing is pushed" |
| partner-job-defaults-016 | guidelines-exact | Compare `codeReviewsGuidelines` with the exact guidelines text | Equal |
| partner-job-defaults-017 | step-fix-command-exact | Compare `codeReviews().steps[2].command` with the exact fix command | Equal |

## Edge Cases

- **Fresh install, no jobs stored**: The controller seeds each job in `all` that the store lacks (see the controller's `jobs()`); the seeded code-reviews job starts disabled (`job-disabled-by-default`). Seeding itself belongs to the controller.
- **Store read fails**: The controller falls back to `all` and logs the failure; the defaults are therefore always available without storage (`pure-constants`). That fallback belongs to the controller.
- **Retired job left behind**: An install that once had the general job keeps its row, file and skill until the coordinator calls the installer's removal with `retiredGeneralID`; `all` never re-creates it (`all-contents`).
- **Reset to default**: Replacing a job's steps or guidelines with `codeReviews()` values restores the original text exactly, because the values are reproducible (`defaults-reproducible`).
- **Placeholders left unfilled**: These constants hold placeholders unresolved. `PartnerStepTemplate.fill` (see Partner Step Template ([adhsdk.ingredient.foundation.partner.partner-step-template](cookbook:211ef664-01fc-45d5-996b-1a0a4167a748))) leaves an unknown placeholder as written, so a value the review service does not supply is typed literally.
- **Empty reviewer model and no superseding commits**: `ReviewService.fill` drops the `--model {model}` option from every step when the reviewer-model setting is empty, so the terminal step then reads `claude --dangerously-skip-permissions`; and `{superseded}` is filled with `none` when no later commit touched the files (a fact of the review service, specified in Partner Review ([adhsdk.ingredient.foundation.partner.partner-review](cookbook:2a298bb0-d8af-40aa-8fec-42dd3b1d8f43)) and not by this type).
- **Command placeholders vs terminal quoting**: Values filled into the terminal step are shell-quoted and values filled into Claude steps are not (a fact of `PartnerStepTemplate`, specified in Partner Step Template ([adhsdk.ingredient.foundation.partner.partner-step-template](cookbook:211ef664-01fc-45d5-996b-1a0a4167a748)) and not by this type).
- **Concurrent access**: Not applicable — every member is a constant or builds a new value, so there is nothing shared to race on.
- **Network, timeouts, offline, boundary values**: Not applicable — the namespace performs no I/O; the 1800-second interval is the one numeric default.

## Configuration
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `codeReviews().scheduleSeconds` | int | 1800 | Default timer interval, in seconds |
| `codeReviews().isEnabled` | bool | false | Whether the job is on at install |
| `codeReviews().steps` | array of `PartnerJobStep` | the three steps above | The default steps; the owner can edit them and reset to this value |
| `codeReviews().guidelines` | string | `codeReviewsGuidelines` | The default guidelines; the owner can edit them and reset to this value |

The ids, `retiredGeneralID`, `codeReviewsGuidelines` and `all` are constants, specified in Behavioral Requirements. The commands and guidelines also rely on values the app supplies when a review starts: `{model}`, `{sha}`, `{fix_branch}` and `{superseded}`, and the tool `partner_review_start` that fills them.
## Deep Linking

Not applicable: the namespace is constants with no URL surface; nothing in the source routes by URL.

## Localization

Not applicable: the job name, step names and the guidelines are English text for the owner's settings and the partner's language model, and the source externalises none of them. The job name `Code reviews` and step names can reach the owner's settings screen as written; a port keeps the guidelines and commands verbatim because the partner's tools and the app match on them.

## Accessibility Options

Not applicable: the namespace renders nothing, so Reduce Motion, Increase Contrast and Differentiate Without Color do not reach it.

## Feature Flags

Not applicable: the source reads no flag. The job's `isEnabled` field is user data and starts false.

## Analytics

Not applicable: the source emits no analytics event.

## Privacy

- **Data collected**: None; the namespace holds constant text.
- **Storage**: None here. The controller stores seeded jobs in the partner store.
- **Transmission**: None here. The guidelines and steps are given to the partner process, and the fix step tells Claude to commit locally and not to push.
- **Retention**: Not applicable; the values are compiled constants.

## Logging

Not applicable: the source makes no log call.

## Platform Notes

- **SwiftUI**: The type carries no UI, so a SwiftUI host uses it unchanged. In Swift it is a case-less `enum` namespace of static members importing only `Foundation`; `all` is a computed property, so each access builds a new array.
- **Compose**: Port as a Kotlin `object PartnerJobDefaults` with `const val` ids and a trimmed raw string (triple-quoted, with `trimIndent`) for the guidelines. Keep paragraph breaks and avoid raw-string `$` interpolation in the placeholders by writing the braces as plain text (they are not Kotlin template syntax unless preceded by a dollar sign).
- **React/Web**: Port as a module exporting constants and a factory function `codeReviews()` that returns a fresh object each call, with the result frozen or copied by consumers so mutations do not leak. Template literals keep the paragraph text; the brace placeholders are literal text there as well because they lack a dollar sign.
- **AppKit / UIKit**: The type is UI-framework agnostic. The macOS settings screens (`PartnerJobsEditorModel` and the code-review settings view controller) read `all` and `codeReviews()` to offer a reset to default.
- **WinUI 3**: Port as a `public static class PartnerJobDefaults` with `public const string CodeReviewsId = "code-reviews"` and `RetiredGeneralId = "general"`, a `const string` (or raw string literal with `"""`) for the guidelines, a static method `CodeReviews()` returning a new `PartnerJob` record each call, and `All` as a static property returning `new[] { CodeReviews() }` so each access allocates a new value. The step commands need no escaping beyond the C# string rules; raw string literals avoid escaping the quoted trailer. The commands target a terminal shell, so on Windows the `claude` invocation in the terminal step needs a shell-appropriate form if the review sessions run in Windows Terminal rather than zsh; the source assumes zsh quoting (see `PartnerStepTemplate`). Persist seeded jobs with the same store as other job data, for example in SQLite under `Windows.Storage.ApplicationData.Current.LocalFolder`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Partner/PartnerJobDefaults.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The built-in code-reviews job ships disabled with a 1800-second timer.
**Rationale**: The job starts Claude sessions with permission prompts off in the owner's repositories, so it must be an explicit opt-in; the 30-minute interval bounds how often the app crawls and the partner starts reviews.
**Approved**: pending

**Decision**: The terminal step opens Claude with `--dangerously-skip-permissions`.
**Rationale**: A review session is driven unattended by the partner, which would otherwise stall on every permission prompt. The "commit only, never push" wording of the fix step is advisory prompt text, not a control: a session with prompts off could still push or write outside its worktree. What limits the damage is that the session starts in its own review worktree and the owner merges the fix branch. The residual risk is accepted, and an owner can edit the step.
**Approved**: pending

**Decision**: The guidelines tell the partner to retry `/code-review` with the range `{sha}^..{sha}` when the bare sha is rejected.
**Rationale**: This is a workaround recorded in the source: the review command's target rules reject a bare sha in some cases, and the range form is accepted, so the partner is told the fallback instead of failing the review.
**Approved**: pending

**Decision**: The retired general job's id is kept as a constant while `all` lists only the code-reviews job.
**Rationale**: Installs made before the general job was retired still hold its row, file and skill; the installer needs the id to remove them. The doc comment on the constant says it is kept only for that.
**Approved**: pending

**Decision**: The fix step skips findings that later commits already changed or removed and requires the report to say which.
**Rationale**: A review runs against one commit but fixes land at the tip of the branch, so a finding may already be obsolete; saying which were skipped keeps the owner able to audit the result.
**Approved**: pending

**Decision**: The unattended review session reads untrusted repository content (commit text, code and files) with permission prompts off, and the risk of prompt injection from it is accepted.
**Rationale**: A review has to read the repository it reviews, and the session is driven without a person at the prompt. The mitigations are the review worktree, the fix branch the owner merges, and the job being disabled until the owner turns it on; nothing in the guidelines or steps screens the content Claude reads.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.user-safety.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | partial | user-safety |

The namespace holds data and builds values; seeding, scheduling and storage live in the controller, coordinator and store, so separation of concerns passes. Tests assert the id list, the step names, the fix step's commit and no-push wording, the guidelines' tool names and range fallback, and the reset to default, and `PartnerJobDefaultsConformanceTests` (Core/Partner) covers all 17 vectors, including the other step fields, the 1800-second timer, the disabled default and the exact texts, so unit-test coverage passes. Known debt: the test `defaultsHaveTheTwoBuiltInJobs` asserts one job; its name is stale from before the general job was retired, and vector 001 follows its assertion. Safe defaults are partial: the job is disabled and the fix step never pushes, but the terminal step skips permission prompts by design.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (PartnerJobDefaultsConformanceTests.swift, 17 of 17 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Quoted the exact guidelines and fix command, rewrote the permission-skip rationale as advisory with accepted residual risk, added a prompt-injection decision, folded step-skip-permissions into step-open-session, trimmed Configuration to editable defaults, linked partner-job, partner-step-template and partner-review, and reworded other types' behavior in edge cases as facts. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |

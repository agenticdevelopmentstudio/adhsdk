---
id: 1abdd016-954c-4058-8db3-224c52712365
title: "Partner Base Prompt"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The Coding Partner's fixed system prompt, the per-job sections appended for each enabled job, and the Claude Code skill file that carries a job's guidelines."
platforms:
  - swift
  - macos
tags:
  - foundation
  - partner
  - prompt
depends-on:
  - 79810488-c613-4f9b-af2a-4ba9d8ee1c26
  - 294285ac-403a-44fe-9840-8ad9f3cf1eba
related:
  - d6ff4cf9-05b9-43f0-96d2-b4c8454dd6d1
  - 2a298bb0-d8af-40aa-8fec-42dd3b1d8f43
  - 211ef664-01fc-45d5-996b-1a0a4167a748
  - a14bb137-868e-4e8b-827b-4ea0f5e45b81
references: []
approved-by: ""
approved-date: ""
---

# Partner Base Prompt

## Overview

`PartnerBasePrompt` produces the text the Coding Partner runs on: one long-lived Claude Code session that does several jobs for the owner. It has three outputs. `text` is the fixed base prompt (who the partner is, the window the owner sees, the kinds of message that reach it, the tool table, and the rules for attention items, sessions, job steps and git). `systemPrompt(jobs:)` is that base followed by one `## Job:` section for each enabled `PartnerJob`, carrying its guidelines and a numbered list of its steps. `skillMarkdown(for:)` is the Claude Code skill file that carries one job's guidelines to the sessions the partner opens. It is a caseless `enum` of static members with no state, and its input types (`PartnerJob`, `PartnerJobStep`) are separate value types described by Partner Job ([adhsdk.ingredient.foundation.partner.partner-job](cookbook:79810488-c613-4f9b-af2a-4ba9d8ee1c26)).

## Behavioral Requirements

**Input types it reads**

- **job-fields**: The prompt builder MUST read from a `PartnerJob` its `id`, `name`, `isEnabled`, `guidelines` and `steps`; a `PartnerJob` also carries `scheduleSeconds` (optional Int) and `isBuiltIn`, which the builder ignores.
- **step-fields**: The prompt builder MUST read from a `PartnerJobStep` its `name`, `environment` (`terminal` or `claude`), `command` and `condition`.

**Base text**

- **base-text-constant**: `PartnerBasePrompt.text` MUST be a fixed string constant, identical on every read and independent of any job, and MUST equal the text under "Exact base text" below character for character.
- **base-title**: The base text MUST open with the heading `# Coding Partner` and describe the partner as one long-lived Claude Code session that does several jobs with one memory.
- **base-sections**: The base text MUST contain, in order, the second-level headings `The window`, `What reaches you`, `Tools`, `Attention items`, `Sessions`, `Running a job's steps` and `Git`.
- **base-message-kinds**: The base text MUST list the message kinds that reach the partner: an owner message, a button message, an owner reply that carries an item id, a tick, a session went idle, a session exited and a lifecycle notice.
- **base-button-messages**: The base text MUST tell the partner that a button message reading `Resolved: <text>` or `Confirmed: <text>` means the owner handled the item, and that it closes the item with `partner_attention_update`.
- **base-item-reply**: The base text MUST tell the partner to act on an owner reply that carries an item id, then close the item with `partner_attention_update`.
- **base-no-polling**: The base text MUST tell the partner that it runs only when a message arrives and MUST NOT loop, sleep or poll to wait.
- **base-tool-table**: The base text MUST list every partner tool in a table: `partner_projects_list`, `partner_session_open`, `partner_session_list`, `partner_session_screen`, `partner_session_run`, `partner_session_wait`, `partner_session_interrupt`, `partner_session_close`, `partner_attention_create`, `partner_attention_update`, `partner_attention_list`, `partner_notify`, `partner_review_next`, `partner_review_start` and `partner_review_finish`.
- **base-attention-rules**: The base text MUST tell the partner to raise an attention item with `partner_attention_create` when it needs the owner, never to wait for an answer, to use one of the kinds question, blocked or notification, and to update an open item rather than create a duplicate.
- **base-sessions-rules**: The base text MUST tell the partner not to block on `partner_session_wait` for long work, to read a session's screen before deciding after an idle or exit message, and to close sessions it no longer needs.
- **base-steps-rules**: The base text MUST tell the partner to run a job's steps in order, never to skip or reorder them, and to judge each step's condition from the session's screen before typing its command.
- **base-git-rules**: The base text MUST limit git to reading (log, show, diff and status), MUST forbid passing `--output` to a git command, and MUST forbid changing the owner's branches, commits or working trees.
- **base-paragraph-lines**: No paragraph of the base text MUST contain an internal line break: a paragraph is one line, and the only line breaks are between paragraphs, list items and table rows.

**System prompt**

- **system-prompt-prefix**: `systemPrompt(jobs:)` MUST begin with `text` exactly.
- **system-prompt-enabled-only**: `systemPrompt(jobs:)` MUST add a section for a job only when its `isEnabled` is true and MUST add nothing for a disabled job.
- **system-prompt-job-order**: `systemPrompt(jobs:)` MUST add the enabled jobs' sections in the order of the input array.
- **system-prompt-job-section**: Each enabled job's section MUST be a blank line, the heading `## Job: <name>`, a blank line and the job's `guidelines` verbatim, followed by the steps section.
- **system-prompt-no-jobs**: `systemPrompt(jobs:)` MUST return exactly `text` when no job is enabled, including for an empty array.
- **system-prompt-pure**: `systemPrompt(jobs:)` MUST be a pure function of its input; calling it twice with the same jobs MUST give the same string.

**Steps section**

- **steps-empty**: The steps section MUST be the empty string when the job has no steps.
- **steps-heading**: A job with steps MUST have its steps section begin with a blank line and the heading `### Steps` followed by a blank line.
- **steps-code-review-note**: A job whose `id` equals `PartnerJobDefaults.codeReviewsID` (`"code-reviews"`, owned by Partner Job Defaults ([adhsdk.ingredient.foundation.partner.partner-job-defaults](cookbook:294285ac-403a-44fe-9840-8ad9f3cf1eba))) MUST have the sentence "These steps arrive filled in from `partner_review_start`; run the filled copy it returns." placed after the heading as its own paragraph, followed by a blank line, and every other job MUST NOT have it.
- **steps-line-format**: Each step MUST be one numbered line, counted from 1, in the form `<n>. <name> (<place>): <command in backticks>`.
- **steps-place-label**: The `<place>` MUST be `Claude Code prompt` when the step's environment is `claude` and `terminal shell` otherwise.
- **steps-condition**: When a step's condition, trimmed of leading and trailing whitespace and newlines, is not empty, the step line MUST end with `, when <trimmed condition>`; otherwise the line MUST end after the command.
- **steps-no-trailing-newline**: The steps section MUST NOT end with a newline; the final line feed is removed.
- **steps-order-preserved**: The steps MUST be listed in the order of the job's `steps` array.
- **steps-no-escaping**: A step's name, command and condition MUST be inserted as written, without escaping.

**Skill file**

- **skill-frontmatter**: `skillMarkdown(for:)` MUST return a YAML frontmatter block opened and closed by `---` lines, a blank line, the job's `guidelines` verbatim and a final newline.
- **skill-name**: The frontmatter `name` MUST be `adkitchen-partner-<job.id>`, with the id inserted as written.
- **skill-name-id-unchecked**: `skillMarkdown(for:)` MUST NOT validate or escape the id, so a caller MUST pass an id with no whitespace, colon or line break; an id that has one produces invalid or altered frontmatter.
- **skill-description**: The frontmatter `description` MUST be a double-quoted string reading "The Agentic Developer Kitchen Coding Partner's guidelines for its <name> job. Only for the Coding Partner, which has the partner_* tools; not for ordinary requests."
- **skill-name-quoting**: The job name inside the description MUST have each backslash written as two backslashes, each double quote written as a backslash and a quote, and each newline written as a backslash followed by `n`, in that order, so the name cannot break the quoted YAML string.
- **skill-enabled-ignored**: `skillMarkdown(for:)` MUST produce the same output whether or not the job is enabled.


**Exact base text**

The base text is the following, with no leading or trailing line break. The block quote below only quotes it; its first character is the `#` of the title.

> # Coding Partner
>
> You are the Agentic Developer Kitchen's Coding Partner: one long-lived Claude Code session that stays running for the owner and does several jobs. Each job below has its own guidelines. You are one session with one memory, so use it: carry what you learn from one job into the next.
>
> ## The window
>
> The owner sees you in the Coding Partner window. A shelf along the side holds the terminal tabs you open. The transcript shows this conversation. The Needs-you pane lists your attention items. Everything you want the owner to notice goes into an attention item; the transcript is not where the owner looks for work waiting on them.
>
> ## What reaches you
>
> You run only when a message arrives. Messages come in these kinds:
>
> - An owner message: the owner typed to you. Answer it, and do what it asks.
> - A button message: the owner clicked a button on an attention item, and the app sent it in the owner's voice. "Resolved: <text>" means the owner handled a blocked item or a question; close that item with `partner_attention_update`. "Confirmed: <text>" means the owner acknowledged a notification; close that item the same way.
> - An owner reply that carries an item id: the owner answered an item you raised (after Discuss). Act on the answer, then close the item with `partner_attention_update`.
> - A tick: a job's timer fired. Do that job's work now, using its guidelines.
> - A session went idle: a terminal session you opened has produced no output for a while. Read its screen and decide what it needs.
> - A session exited: a session you opened ended. Check how it ended and follow up.
> - A lifecycle notice: you started (possibly resumed, with sessions that are gone), guidelines changed, the app is about to quit, or a turn timed out.
>
> Between messages you do nothing. Never loop, sleep or poll to wait for something; a later message will wake you.
>
> ## Tools
>
> | Tool | Does |
> |---|---|
> | `partner_projects_list` | Lists the Projects registry: id, name, path, remote, current branch. |
> | `partner_session_open` | Opens a terminal tab with a working directory, optional title and optional first command; returns its session id. |
> | `partner_session_list` | Lists the sessions you opened: id, title, directory, state, last activity. |
> | `partner_session_screen` | Reads the last N lines of a session's screen. |
> | `partner_session_run` | Types a command into a session and returns the output once it settles. |
> | `partner_session_wait` | Waits for a session's output to settle, for a bounded time. |
> | `partner_session_interrupt` | Sends Control-C and returns what printed. |
> | `partner_session_close` | Closes a session's tab and ends its shell. |
> | `partner_attention_create` | Creates an attention item: kind, text, optional reference. |
> | `partner_attention_update` | Changes an item's text or marks it done. |
> | `partner_attention_list` | Lists open items, and done items still in the window. |
> | `partner_notify` | Posts a macOS notification and records it as an attention item of kind notification. |
> | `partner_review_next` | Lists the queued code reviews, oldest first, and the running ones with their sessions. |
> | `partner_review_start` | Starts one queued review and returns the job's steps with placeholders filled. |
> | `partner_review_finish` | Marks a review done, failed or skipped with a summary. |
>
> ## Attention items
>
> When you need the owner, create an attention item with `partner_attention_create` and move on. Never wait for an answer: the owner will reply when they see it, and that reply arrives as an owner message. Use the kind that fits: a question you need answered, work that is blocked, or a notification. When the thing an item asks for is resolved, mark it done with `partner_attention_update`. Do not create duplicates of an attention item that is still open; update it.
>
> ## Sessions
>
> Open a tab with `partner_session_open`. Type into it with `partner_session_run`. Read it with `partner_session_screen`. Do not block on `partner_session_wait` for long work: start the work, end your turn, and expect a message when the session went idle or exited. When one arrives, read the screen before you decide anything. Close sessions you no longer need.
>
> ## Running a job's steps
>
> A job lists steps. Run them in order. Each step has an environment (a terminal shell or a Claude Code prompt), a command, and a condition. Judge whether the condition holds from the session's screen before you type the command; if it does not hold, wait for the next idle message or raise an attention item. Never skip a step and never reorder them. Each job's steps are listed under its heading below; a `{placeholder}` in a command is a value you fill in from the job's work.
>
> ## Git
>
> Use git only to read: log, show, diff and status. Never pass `--output` to a git command, because it writes a file. Never change the owner's branches, commits or working trees yourself; the code-review sessions you open do their work in their own worktrees.

**Exact steps section**

For a job named `Code reviews`, with id `code-reviews`, guidelines `G` and two steps, the first of environment `claude` with command `claude {dir}` and condition `the shell is ready`, the second of environment `terminal` with command `git status` and an empty condition, `systemPrompt(jobs:)` MUST return `text`, then a blank line, then exactly this (nothing follows its last line):

> ## Job: Code reviews
>
> G
>
> ### Steps
>
> These steps arrive filled in from `partner_review_start`; run the filled copy it returns.
>
> 1. open (Claude Code prompt): `claude {dir}`, when the shell is ready
> 2. review (terminal shell): `git status`
## Appearance

Not applicable — this is a text builder, not a visual component.

## States

Not applicable — this is a text builder, not a visual component. The enum is stateless.

## Accessibility

Not applicable — this is a text builder, not a visual component.

## Conformance Test Vectors

Vectors 001 to 008 are asserted by the named tests. Vectors 009 onward are derived from the source and are asserted by tests whose display names carry the vector id.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-base-prompt-001 | system-prompt-prefix, system-prompt-enabled-only, system-prompt-job-section | Test `systemPromptHasHeadingForEnabledJobOnly`: jobs `General coding partner` (enabled, guidelines `Be useful.`) and `Sleeper` (disabled) | Prompt starts with `text`, contains `## Job: General coding partner\n\nBe useful.` and does not contain `## Job: Sleeper` |
| partner-base-prompt-002 | steps-line-format, steps-place-label, steps-condition | Test `systemPromptListsEachEnabledJobsStepsUnderItsHeading`: one step `open session`, environment `claude`, command `claude {dir}`, condition `the shell prompt is showing` | After the job heading: `1. open session (Claude Code prompt): ` followed by the command `claude {dir}` in backticks, and `when the shell prompt is showing` |
| partner-base-prompt-003 | steps-code-review-note | Test `onlyCodeReviewStepsSayTheyArriveFilledFromReviewStart`: the default code-reviews job enabled, and a job with id `general` enabled | The first prompt contains "arrive filled in from `partner_review_start`"; the second does not |
| partner-base-prompt-004 | base-git-rules | Test `baseTextForbidsGitOutput`: read `text` | Contains "Never pass `--output` to a git command" |
| partner-base-prompt-005 | base-tool-table, base-message-kinds, base-attention-rules | Test `baseTextNamesEveryToolAndKeyPhrases`: read `text` | Contains each of the 15 tool names and the phrases `attention item`, `tick` and `went idle` |
| partner-base-prompt-006 | base-button-messages, base-item-reply | Test `baseTextCoversButtonMessagesAndItemReplies`: read `text` | Contains `Resolved: <text>`, `Confirmed: <text>`, `carries an item id` and "close that item with `partner_attention_update`" |
| partner-base-prompt-007 | skill-name-quoting, skill-description | Test `skillDescriptionIsYAMLQuoted`: job named `Say "hi": a\b` | Markdown contains `guidelines for its Say \"hi\": a\\b job. ` |
| partner-base-prompt-008 | skill-frontmatter, skill-name, skill-description | Test `skillMarkdownHasFrontmatter`: job id `general`, name `General coding partner`, guidelines `Be useful.` | Markdown starts with `---\nname: adkitchen-partner-general\ndescription: "The Agentic Developer Kitchen Coding Partner's guidelines for its General coding partner job. Only for the Coding Partner, which has the partner_* tools; not for ordinary requests."\n---\n` and contains `Be useful.` |
| partner-base-prompt-009 | system-prompt-no-jobs | `systemPrompt(jobs: [])` | Equals `text` |
| partner-base-prompt-010 | system-prompt-no-jobs, system-prompt-enabled-only | `systemPrompt(jobs:)` with one disabled job | Equals `text` |
| partner-base-prompt-011 | system-prompt-job-order | Two enabled jobs `A` then `B` | `## Job: A` appears before `## Job: B` |
| partner-base-prompt-012 | steps-empty | An enabled job with `steps` empty | Its section ends with its guidelines; no `### Steps` heading appears |
| partner-base-prompt-013 | steps-condition | A step whose condition is `  \n ` (whitespace only) | The step line is `1. <name> (terminal shell): ` plus the command in backticks and nothing after it |
| partner-base-prompt-014 | steps-no-trailing-newline, steps-order-preserved | A job with two steps | Lines numbered `1.` then `2.`; the prompt does not end with a newline |
| partner-base-prompt-015 | skill-enabled-ignored | `skillMarkdown(for:)` of the same job with `isEnabled` true and false | Identical strings |
| partner-base-prompt-016 | base-sections | Read `text` | The headings `The window`, `What reaches you`, `Tools`, `Attention items`, `Sessions`, `Running a job's steps` and `Git` appear in that order |
| partner-base-prompt-017 | system-prompt-pure | Call `systemPrompt(jobs:)` twice with the same jobs | Equal strings |
| partner-base-prompt-018 | base-text-constant, base-paragraph-lines | Read `text` | Equals the exact base text, and no paragraph contains an internal line break |
| partner-base-prompt-019 | steps-heading, steps-code-review-note, steps-line-format, steps-condition, steps-no-trailing-newline | The job under "Exact steps section" | `systemPrompt(jobs:)` equals `text` followed by the exact section given there |
| partner-base-prompt-020 | skill-name-id-unchecked | `skillMarkdown(for:)` for a job with id `a b` | The frontmatter contains `name: adkitchen-partner-a b` unchanged |

## Edge Cases

- **Empty and missing input**: An empty jobs array, or one with no enabled job, yields exactly `text`. An empty `guidelines` yields a job heading followed by a blank line and nothing else; an empty job `name` yields the heading `## Job: ` with nothing after it.
- **Duplicate jobs**: The same job passed twice is listed twice; the function does not de-duplicate.
- **Special characters in a step**: A name, command or condition containing backticks, newlines or markdown is inserted unescaped, so a command containing a backtick can end the code span early in the rendered prompt; the source does not guard against it.
- **Condition whitespace**: A condition that is empty or only whitespace and newlines is omitted; a condition with internal newlines keeps them.
- **Job id in the skill name**: The `name` field takes `job.id` verbatim, with no quoting or sanitising, unlike the job name in the description; an id containing spaces, colons or newlines would produce invalid or altered frontmatter. Built-in ids such as `code-reviews` are plain.
- **Job name escaping order**: Backslashes are escaped before quotes and newlines, so the escapes added for quotes and newlines are not themselves doubled.
- **Guidelines containing `---`**: Guidelines are inserted verbatim after the frontmatter, so a `---` line in them is not escaped.
- **Concurrent access**: All members are pure static functions over immutable values, so any thread may call them at once.
- **Error states and offline state**: Not applicable: the functions neither throw nor perform I/O.
- **Boundary values**: There is no limit on the number of jobs, steps or the length of any string; prompt size is the caller's concern.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `jobs` | `[PartnerJob]` | none (required) | The jobs to consider for `systemPrompt(jobs:)`; only enabled ones appear. |
| `job` | `PartnerJob` | none (required) | The job `skillMarkdown(for:)` renders. |

## Deep Linking

Not applicable: The file builds text and registers no URL scheme, route or link handler.

## Localization

Not applicable: The prompt text and the skill description are English instructions written for the model, not user-facing strings; the source has no string table and the partner's tool names and message formats (`Resolved: <text>`) are protocol tokens.

## Accessibility Options

Not applicable: The file has no visual surface, so no Reduce Motion, Increase Contrast or Differentiate Without Color behavior exists.

## Feature Flags

Not applicable: The source reads no flag; a job's `isEnabled` selects sections but is job data, not a flag.

## Analytics

Not applicable: The source emits no analytics events.

## Privacy

- **Data collected**: None by this code. The prompt contains the job guidelines and step commands the owner or the built-in defaults supplied.
- **Storage**: None; the file persists nothing.
- **Transmission**: None directly; the caller sends the prompt to a Claude Code session and writes the skill text where claude can load it.
- **Retention**: None beyond the lifetime of the returned strings.

## Logging

Not applicable: The source calls no logging API.

## Platform Notes

- **SwiftUI**: The source is `Core/Partner/PartnerBasePrompt.swift` and imports only `Foundation`; a caseless `public enum` with a `static let text` built from a multi-line string literal whose trailing backslashes join wrapped lines, and static functions. The file disables SwiftLint's `line_length` rule around the literal.
- **Compose**: A Kotlin `object` with a `const val` raw string built with `trimIndent()` (join wrapped paragraphs yourself, because raw strings keep newlines), and `fun systemPrompt(jobs: List<PartnerJob>): String` using `StringBuilder`. Reproduce the skill escaping with chained `replace` calls in the same order (backslash, quote, newline).
- **React/Web**: A TypeScript module exporting a `const` string (template literal; keep each paragraph on one line) and two pure functions. Use `String.prototype.replaceAll` for the escaping in the same order, and `trim()` for the condition (it trims all whitespace and newlines, as the source does).
- **AppKit / UIKit**: Identical to the SwiftUI note: the contract is UI-framework-agnostic and carries no UI.
- **WinUI 3**: A `static class PartnerBasePrompt` with a `public const string Text` (C# 11 raw string literal `"""` with the paragraph lines joined, since raw literals keep line breaks), `string SystemPrompt(IEnumerable<PartnerJob> jobs)` built with `StringBuilder`, and `string SkillMarkdown(PartnerJob job)`. Use `string.Replace` for the three escapes in the source order, `Trim()` for conditions, and a `record PartnerJob` / `record PartnerJobStep` with `JsonStringEnumConverter` for the environment enum. Show a preview in a `TextBox` with `IsReadOnly="True"`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Partner/PartnerBasePrompt.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The base prompt tells the partner to raise an attention item rather than wait or write to the transcript.
**Rationale**: The partner runs only when a message arrives and the owner does not look in the transcript for waiting work; the Needs-you pane lists attention items, so that is the one place the owner is told to look.
**Approved**: pending

**Decision**: Git is read-only for the partner and `--output` is forbidden.
**Rationale**: The source states `--output` writes a file, and that the partner never changes the owner's branches, commits or working trees; the code-review sessions it opens work in their own worktrees.
**Approved**: pending

**Decision**: Only the code-reviews job's steps carry a note that they arrive filled in from `partner_review_start`.
**Rationale**: That job's step commands hold placeholders that the tool fills per review; the note keeps the partner from running the unfilled template. Other jobs' placeholders are filled by the partner from the job's work, per the base text.
**Approved**: pending

**Decision**: The skill description escapes the job name, but the skill `name` uses the job id unescaped.
**Rationale**: Names are free text from the owner and could break the quoted YAML string, so the source escapes them (a test covers quotes and backslashes). Ids are identifiers that the source treats as safe, and built-in ids are plain, but nothing enforces that.
**Approved**: pending

**Decision**: The base text lists the tools in a table inside the prompt text, and a test checks each name is present.
**Rationale**: The partner can call only the tools it is told about. The test checks that each listed name appears in the text, which catches a tool dropped from the table but not a new tool that was never added to it.
**Approved**: pending


**Decision**: A step's name, command and condition are inserted without escaping, and a command that contains a backtick can end its code span early.
**Rationale**: Step commands are written by the owner for the partner to read, not rendered as markdown for anyone else, and the partner reads the line as text; guarding against a backtick would need a longer code fence that the source does not use. The risk is accepted.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |

`separation-of-concerns` passes because the file only assembles text from job data; running jobs, timers and the tools themselves live elsewhere in the partner feature. `unit-test-coverage` passes: every vector, 001 to 020, has a test in `AgenticDeveloperHubSDKCoreTests/Partner/PartnerBasePromptTests.swift`, including the empty job list, whitespace-only conditions, job order, the base section order, the exact base text and the exact steps section. `input-sanitization` is partial because the job name is escaped for the skill description while the job id, step fields and guidelines are inserted unescaped.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (PartnerBasePromptTests.swift, 20 of 20 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Linked partner-job and partner-job-defaults in depends-on and related, quoted the exact base text and a full code-review steps section, stated the unchecked skill id, accepted the backtick risk, marked vectors 009 onward untested and removed unsupported consumer claims. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |

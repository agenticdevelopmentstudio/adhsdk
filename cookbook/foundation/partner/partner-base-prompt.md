---
id: 1abdd016-954c-4058-8db3-224c52712365
title: "Partner Base Prompt"
type: ingredient
version: 1.0.0
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
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Partner Base Prompt

## Overview

`PartnerBasePrompt` produces the text the Coding Partner runs on: one long-lived Claude Code session that does several jobs for the owner. It has three outputs. `text` is the fixed base prompt (who the partner is, the window the owner sees, the kinds of message that reach it, the tool table, and the rules for attention items, sessions, job steps and git). `systemPrompt(jobs:)` is that base followed by one `## Job:` section for each enabled `PartnerJob`, carrying its guidelines and a numbered list of its steps. `skillMarkdown(for:)` is the Claude Code skill file that carries one job's guidelines to the sessions the partner opens. It is a caseless `enum` of static members with no state, and its input types (`PartnerJob`, `PartnerJobStep`) are separate value types.

## Behavioral Requirements

**Input types it reads**

- **job-fields**: The prompt builder MUST read from a `PartnerJob` its `id`, `name`, `isEnabled`, `guidelines` and `steps`; a `PartnerJob` also carries `scheduleSeconds` (optional Int) and `isBuiltIn`, which the builder ignores.
- **step-fields**: The prompt builder MUST read from a `PartnerJobStep` its `name`, `environment` (`terminal` or `claude`), `command` and `condition`.

**Base text**

- **base-text-constant**: `PartnerBasePrompt.text` MUST be a fixed string constant, identical on every read and independent of any job.
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
- **base-line-continuations**: Each paragraph of the base text MUST be a single logical line: the source wraps paragraphs with trailing backslash continuations, so the wrapping is not part of the text.

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
- **steps-code-review-note**: A job whose `id` equals `PartnerJobDefaults.codeReviewsID` (`"code-reviews"`) MUST have the sentence "These steps arrive filled in from `partner_review_start`; run the filled copy it returns." placed after the heading, and no other job MUST have it.
- **steps-line-format**: Each step MUST be one numbered line, counted from 1, in the form `<n>. <name> (<place>): <command in backticks>`.
- **steps-place-label**: The `<place>` MUST be `Claude Code prompt` when the step's environment is `claude` and `terminal shell` otherwise.
- **steps-condition**: When a step's condition, trimmed of leading and trailing whitespace and newlines, is not empty, the step line MUST end with `, when <trimmed condition>`; otherwise the line MUST end after the command.
- **steps-no-trailing-newline**: The steps section MUST NOT end with a newline; the final line feed is removed.
- **steps-order-preserved**: The steps MUST be listed in the order of the job's `steps` array.
- **steps-no-escaping**: A step's name, command and condition MUST be inserted as written, without escaping.

**Skill file**

- **skill-frontmatter**: `skillMarkdown(for:)` MUST return a YAML frontmatter block opened and closed by `---` lines, a blank line, the job's `guidelines` verbatim and a final newline.
- **skill-name**: The frontmatter `name` MUST be `adkitchen-partner-<job.id>`, with the id inserted as written.
- **skill-description**: The frontmatter `description` MUST be a double-quoted string reading "The Agentic Developer Kitchen Coding Partner's guidelines for its <name> job. Only for the Coding Partner, which has the partner_* tools; not for ordinary requests."
- **skill-name-quoting**: The job name inside the description MUST have each backslash written as two backslashes, each double quote written as a backslash and a quote, and each newline written as a backslash followed by `n`, in that order, so the name cannot break the quoted YAML string.
- **skill-enabled-ignored**: `skillMarkdown(for:)` MUST produce the same output whether or not the job is enabled.

## Appearance

Not applicable — this is a text builder, not a visual component.

## States

Not applicable — this is a text builder, not a visual component. The enum is stateless.

## Accessibility

Not applicable — this is a text builder, not a visual component.

## Conformance Test Vectors

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
| `PartnerJobDefaults.codeReviewsID` | String | `"code-reviews"` | The job id that gets the filled-from-`partner_review_start` note on its steps. |

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

- **SwiftUI**: The source is `Core/Partner/PartnerBasePrompt.swift` and imports only `Foundation`; a caseless `public enum` with a `static let text` built from a multi-line string literal whose trailing backslashes join wrapped lines, and static functions. A SwiftUI settings view that edits jobs simply calls `systemPrompt(jobs:)` to preview the result. The file disables SwiftLint's `line_length` rule around the literal.
- **Compose**: A Kotlin `object` with a `const val` raw string built with `trimIndent()` (join wrapped paragraphs yourself, because raw strings keep newlines), and `fun systemPrompt(jobs: List<PartnerJob>): String` using `StringBuilder`. Reproduce the skill escaping with chained `replace` calls in the same order (backslash, quote, newline).
- **React/Web**: A TypeScript module exporting a `const` string (template literal; keep each paragraph on one line) and two pure functions. Use `String.prototype.replaceAll` for the escaping in the same order, and `trim()` for the condition (it trims all whitespace and newlines, as the source does).
- **AppKit / UIKit**: Identical to the SwiftUI note: the contract is UI-framework-agnostic; a macOS settings pane shows the prompt in a text view.
- **WinUI 3**: A `static class PartnerBasePrompt` with a `public const string Text` (C# 11 raw string literal `"""` with the paragraph lines joined, since raw literals keep line breaks), `string SystemPrompt(IEnumerable<PartnerJob> jobs)` built with `StringBuilder`, and `string SkillMarkdown(PartnerJob job)`. Use `string.Replace` for the three escapes in the source order, `Trim()` for conditions, and a `record PartnerJob` / `record PartnerJobStep` with `JsonStringEnumConverter` for the environment enum. Show a preview in a `TextBox` with `IsReadOnly="True"`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Partner/PartnerBasePrompt.swift` | confirmed (1.0.0) |
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
**Rationale**: The partner can call only the tools it is told about; tying the table to a test keeps the prompt and the tool surface from drifting apart.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |

`separation-of-concerns` passes because the file only assembles text from job data; running jobs, timers and the tools themselves live elsewhere in the partner feature. `unit-test-coverage` is partial: `AgenticDeveloperHubSDKCoreTests/Partner/PartnerBasePromptTests.swift` covers the enabled-only job sections, step lines and conditions, the code-review note, the git rule, the tool names and key phrases, the button-message phrases, YAML quoting of the job name and the skill frontmatter, but not an empty job list, whitespace-only conditions, job order or the base section order. `input-sanitization` is partial because the job name is escaped for the skill description while the job id, step fields and guidelines are inserted unescaped.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |

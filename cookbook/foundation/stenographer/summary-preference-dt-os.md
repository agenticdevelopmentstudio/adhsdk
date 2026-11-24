---
id: 844fde57-2231-4516-bcc9-a93c56d74a2d
title: "Summary Preference Constants"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The AI-summaries tuning knobs shared by the settings panel and the daemon: defaults, accepted ranges, the clamp, the title character cap and the settings-table keys."
platforms:
  - swift
  - macos
tags:
  - foundation
  - stenographer
  - dto
  - settings
depends-on: []
related:
  - a8bfcd0b-0759-4801-aaf6-a14d7aa3fe49
references: []
approved-by: ""
approved-date: ""
---

# Summary Preference Constants

## Overview

This file holds the numbers and names both sides of the AI-summaries feature read, so the app's settings panel and the daemon's summarizer cannot drift. `SummaryDefaults` carries the prompt template, the `{maxWords}` placeholder and the default value of each knob, plus the one derived function `characterCap(maxWords:)`. `SummaryLimits` carries the accepted range of each numeric knob and `clamp(_:to:)`. `SummarySettingsKeys` names the daemon settings-table keys the values persist under. The app owns the values (they live in `UserSettings` and are pushed to the daemon over HTTP: `StenographerHTTPClient.setSummaryPreferences` is the current push path, and the "over XPC" wording in the source's doc comment is stale); the daemon persists them and falls back to these defaults for anything never pushed, so the panel's "Reset to Defaults" lands where a never-configured daemon already sits. The code holds constants and two pure functions; reading the settings table, pushing the values and cleaning a reply live in `SummaryPrefs`, `StenographerSummaryPrefsPush` and `DaemonSessionSummarizer`, outside these sources.

## Behavioral Requirements

- **placeholder-token**: `SummaryDefaults.maxWordsPlaceholder` MUST be the literal text `{maxWords}`.
- **placeholder-substitution-site**: A consumer MUST substitute the effective max-word count for each occurrence of the placeholder in the prompt; `SummaryPrefs.resolvedPrompt` is the source's one substitution.
- **placeholder-dropped**: A user-edited prompt that drops the placeholder MUST keep its wording unchanged, so the model is not told the word cap while the cap still applies to the reply; the source's comment says an explicit prompt beats "a hidden sentence appended behind the user's back".
- **default-prompt**: `SummaryDefaults.prompt` MUST be the system prompt template that opens `You write a title of at most {maxWords} words for a coding session.` and carries the placeholder once, in that first sentence.
- **default-prompt-instructions**: The default prompt MUST tell the model to start with a verb ending in -ing, to be brief and plain, never to ask questions, explain or say it lacks context, to guess from what is there when the activity is unclear, and to output only the short phrase.
- **default-prompt-examples**: The default prompt MUST give four examples: `fixing the sessions window UI`, `adding keyboard shortcuts`, `cleaning up old code` and `exploring the codebase`.
- **default-prompt-verbatim**: `SummaryDefaults.prompt` MUST be exactly this text, with `{maxWords}` as the placeholder and no newline:

  ```text
  You write a title of at most {maxWords} words for a coding session. Start with a verb ending in -ing. Be brief and plain — no jargon, no technical detail, no explanation. NEVER ask questions. NEVER explain. NEVER say you lack context. If the activity is unclear, make your best guess from what is there. Output ONLY the short phrase and nothing else. Examples: "fixing the sessions window UI", "adding keyboard shortcuts", "cleaning up old code", "exploring the codebase".
  ```
- **default-prompt-single-line**: The default prompt MUST be one logical line: each source line break is a line continuation, so the string holds no newline.
- **default-max-words**: `SummaryDefaults.maxWords` MUST be 8.
- **default-activity-lines**: `SummaryDefaults.activityLines` MUST be 60, the count of the session's most recent events that go into the prompt.
- **default-detail-chars**: `SummaryDefaults.detailChars` MUST be 120, the per-event detail cap inside the prompt.
- **default-interval-minutes**: `SummaryDefaults.intervalMinutes` MUST be 5, how often the daemon looks for sessions that still need a summary.
- **default-max-per-run**: `SummaryDefaults.maxPerRun` MUST be 5, the sessions one pass summarizes.
- **default-timeout-seconds**: `SummaryDefaults.timeoutSeconds` MUST be 60, the per-completion budget.
- **max-words-double-duty**: The max-word cap MUST be told to the model through the placeholder and enforced on the reply, because the source states a small local model routinely overruns it.
- **character-cap-formula**: `characterCap(maxWords:)` MUST return the larger of 80 and ten times `maxWords`.
- **character-cap-purpose**: The character cap MUST serve as the belt-and-braces limit on a title that is one enormous word, such as a pasted path or a wall of punctuation.
- **character-cap-shared-with-purge**: The startup purge of overlong summaries MUST use the same `characterCap(maxWords:)` value as the summarizer; a purge threshold below the cap wipes titles the summarizer just wrote and re-queues them forever.
- **limit-max-words**: `SummaryLimits.maxWords` MUST be the closed range 4 through 20.
- **limit-activity-lines**: `SummaryLimits.activityLines` MUST be the closed range 10 through 400.
- **limit-detail-chars**: `SummaryLimits.detailChars` MUST be the closed range 40 through 500.
- **limit-interval-minutes**: `SummaryLimits.intervalMinutes` MUST be the closed range 1 through 240.
- **limit-max-per-run**: `SummaryLimits.maxPerRun` MUST be the closed range 1 through 50.
- **limit-timeout-seconds**: `SummaryLimits.timeoutSeconds` MUST be the closed range 10 through 600.
- **defaults-inside-limits**: Each numeric default MUST lie inside its range, so a reset value is never clamped.
- **clamp-contract**: `clamp(_:to:)` MUST return the range's lower bound for a value below it, its upper bound for a value above it, and the value itself otherwise.
- **clamp-both-sides**: The app and the daemon MUST both clamp through `SummaryLimits`, so an out-of-range value from an older app or a hand-rolled HTTP POST lands on a sane number instead of wedging the summarizer.
- **settings-key-names**: `SummarySettingsKeys` MUST name seven keys: `prompt` as `ai_summary_prompt`, `maxWords` as `ai_summary_max_words`, `activityLines` as `ai_summary_activity_lines`, `detailChars` as `ai_summary_detail_chars`, `intervalMinutes` as `ai_summary_interval_minutes`, `maxPerRun` as `ai_summary_max_per_run` and `timeoutSeconds` as `ai_summary_timeout_seconds`.
- **settings-key-home**: The keys MUST live in this file so the wire contract and the storage contract are read from one place.
- **daemon-fallback**: A daemon MUST fall back to `SummaryDefaults` for any knob never pushed; `SummaryPrefs` does so for a missing, blank (prompt) or unparseable (number) stored value.
- **type-shape**: `SummaryDefaults`, `SummaryLimits` and `SummarySettingsKeys` MUST be caseless `public enum` namespaces that cannot be instantiated.
- **no-persistence-here**: These types MUST NOT read or write the settings table themselves; clamping a stored or pushed value is the caller's act.

## Appearance

Not applicable — this is a set of constants and two pure functions, not a visual component.

## States

Not applicable — this is a set of constants and two pure functions, not a visual component.

## Accessibility

Not applicable — this is a set of constants and two pure functions, not a visual component.

## Conformance Test Vectors

No test sits beside the source file. Vectors 004 to 009 come from the tests that exercise these constants through the daemon (`DaemonSessionSummarizerTests`, `PreferencesServiceTests`); the rest follow from the source's own values and logic.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| summary-preference-dt-os-001 | character-cap-formula | `characterCap(maxWords: 8)` and `characterCap(maxWords: 4)` | 80 for each, because ten times the words is below 80 |
| summary-preference-dt-os-002 | character-cap-formula | `characterCap(maxWords: 20)` | 200 |
| summary-preference-dt-os-003 | character-cap-formula | `characterCap(maxWords: 8)` against `characterCap(maxWords: 9)` | 80, then 90: the floor ends above 8 words |
| summary-preference-dt-os-004 | clamp-contract, clamp-both-sides | `PreferencesService.setSummary(maxWords: Int.max)` (`testSummaryNumbersAreClamped`) | the response's `maxWords` equals `SummaryLimits.maxWords.upperBound`, 20 |
| summary-preference-dt-os-005 | clamp-contract, daemon-fallback | settings rows `ai_summary_max_words` = `999` and `ai_summary_activity_lines` = `0` (`testSummaryPrefsClampOutOfRangeStoredValues`) | `SummaryPrefs.maxWords` is 20 and `SummaryPrefs.activityLines` is 10 |
| summary-preference-dt-os-006 | daemon-fallback | `ai_summary_timeout_seconds` = `not a number` (`testSummaryPrefsClampOutOfRangeStoredValues`) | `SummaryPrefs.timeoutSeconds` is 60, the default |
| summary-preference-dt-os-007 | daemon-fallback, default-max-words, default-interval-minutes | an empty settings table (`testSummaryPrefsFallBackToTheSharedDefaults`) | every `SummaryPrefs` accessor returns its `SummaryDefaults` value, the prompt included |
| summary-preference-dt-os-008 | placeholder-substitution-site, placeholder-dropped | prompt `Write {maxWords} words, tops.` with max words 12, then prompt `Write a title.` (`testResolvedPromptSubstitutesTheWordCap`) | `Write 12 words, tops.`, then `Write a title.` unchanged |
| summary-preference-dt-os-009 | max-words-double-duty | `cleanSummary` of a thirteen-word reply with `maxWords: 4`, then 20 (`testCleanSummaryCapsAtTheConfiguredWordCount`) | `fixing the sessions window`, then the reply unchanged |
| summary-preference-dt-os-010 | clamp-contract | `clamp(3, to: 4...20)`, `clamp(12, to: 4...20)`, `clamp(25, to: 4...20)` | 4, 12, 20 |
| summary-preference-dt-os-011 | settings-key-names | `SummarySettingsKeys.timeoutSeconds` | `ai_summary_timeout_seconds` |
| summary-preference-dt-os-012 | limit-max-words, limit-activity-lines, limit-detail-chars, limit-interval-minutes, limit-max-per-run, limit-timeout-seconds | the six `SummaryLimits` ranges | 4...20, 10...400, 40...500, 1...240, 1...50, 10...600 |
| summary-preference-dt-os-013 | default-prompt, placeholder-token | count of `{maxWords}` in `SummaryDefaults.prompt` | 1, in the first sentence |
| summary-preference-dt-os-014 | defaults-inside-limits | each default against its range | 8, 60, 120, 5, 5 and 60 each inside their ranges |
| summary-preference-dt-os-015 | default-prompt-single-line | `SummaryDefaults.prompt.contains("\n")` | false |

## Edge Cases

- **Empty or missing input**: a knob never pushed MUST read as its `SummaryDefaults` value; a blank prompt (empty or whitespace only) MUST read as the default prompt, because `SummaryPrefs.prompt` treats it as "never configured" and an empty system prompt would turn a titling model into a chatbot.
- **Boundary values**: `clamp` MUST return the bound itself for a value equal to either bound, and `characterCap(maxWords:)` MUST stay at 80 for every `maxWords` up to 8.
- **Out-of-range input**: a value below or above its range MUST clamp to the nearest bound, never be rejected; `Int.max` clamps to the upper bound without overflow because `clamp` only compares.
- **Unparseable stored value**: a stored number that is not an integer MUST fall back to the default, not to a bound; the clamp is not reached. The parse step is in `RawSetting`, outside this file.
- **Prompt without the placeholder**: a prompt that drops `{maxWords}` MUST be sent verbatim; the reply is still trimmed to the cap.
- **Purge threshold drift (known non-conformance with character-cap-shared-with-purge)**: a purge threshold below `characterCap(maxWords:)` would wipe titles just written and re-queue them forever; the purge MUST take its number from this function. The current source does not meet that: `clearOverlongSummaries` (in `SessionRecords`) defaults its `maxCharacters` to the cap at the default max words plus 10 (90) and also blanks any summary containing a newline, and no caller in the repository passes the configured cap. With `maxWords` at 20 the cap is 200, so the purge wipes and re-queues every ended session's title longer than 90 characters at each daemon start. An implementation MUST pass `SummaryDefaults.characterCap(maxWords:)` for the configured limit and MUST NOT copy the `+ 10` default.
- **Inverted or empty range**: `clamp` does not check the range it is given; the six ranges in this file are fixed and valid, and a caller passing another range owns it.
- **Concurrent access**: every member is an immutable `static let` or a pure function, so concurrent reads are safe with no ordering rule.
- **Error and offline states**: this code makes no network, file or database call and has no error path; a failed settings read is `SummaryPrefs`'s fallback to the default.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| prompt | String | the default prompt, with `{maxWords}` | System prompt template, stored under `ai_summary_prompt`. |
| maxWords | Int | 8 (range 4 to 20) | Word cap on a title, stored under `ai_summary_max_words`. |
| activityLines | Int | 60 (range 10 to 400) | Most recent session events in the prompt, stored under `ai_summary_activity_lines`. |
| detailChars | Int | 120 (range 40 to 500) | Per-event detail cap in the prompt, stored under `ai_summary_detail_chars`. |
| intervalMinutes | Int | 5 (range 1 to 240) | Minutes between looks for sessions needing a summary, stored under `ai_summary_interval_minutes`. |
| maxPerRun | Int | 5 (range 1 to 50) | Sessions summarized per pass, stored under `ai_summary_max_per_run`. |
| timeoutSeconds | Int | 60 (range 10 to 600) | Per-completion budget in seconds, stored under `ai_summary_timeout_seconds`. |

## Deep Linking

Not applicable: these constants define no URL or deep link.

## Localization

`SummaryDefaults.prompt` is a hardcoded English system prompt for the model, with English examples and no string table; it is edited verbatim by the user in Settings → AI Summaries, not shown as interface text by this code.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: none by this code; the source describes `detailChars` as data minimization, capping how much of each event's detail goes into the prompt.
- **Storage**: none here; the daemon persists the values in its settings table under the `SummarySettingsKeys` names.
- **Transmission**: none here; the app pushes the values to the daemon (the HTTP client posts them to the daemon's loopback address; the source's "over XPC" comment is stale), and this code opens no connection.
- **Retention**: none defined by this code.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Not used here; the constants are plain Swift enums. A SwiftUI port would bind `SummaryLimits` ranges to `Picker` and `Stepper` controls and take initial values from `SummaryDefaults`.
- **Compose**: Kotlin `object` declarations with `const val` for the numbers and `IntRange` for each range; `coerceIn` replaces `clamp`; Kotlin has no line-continuation escape, so build the prompt by concatenation or `trimIndent` plus replacing newlines with spaces.
- **React/Web**: TypeScript `as const` objects, each range a pair of numbers, and `Math.min(max, Math.max(min, value))` for the clamp; build the prompt as one string with no newlines.
- **AppKit / UIKit**: The settings panel (`AISummariesSettingsPanel`, AppKit) binds a text area for the prompt, pop-up menus for the word limit, activity lines, detail, interval and timeout, and a stepper for sessions per pass to `UserSettings` values, with `SummaryLimits` giving the choices and stepper bounds. The `UserSettings` entries take their defaults from `SummaryDefaults`, and "Reset to Defaults" removes the stored values so they read back as the current defaults. The source is Swift in `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/SummaryPreferenceDTOs.swift`: caseless `public enum` namespaces, `ClosedRange<Int>` ranges, and a multi-line string literal whose trailing backslashes join the lines.
- **WinUI 3**: Use `static class` types with `public const int` for the numbers and a small `readonly record struct IntRange(int Min, int Max)` for each range (C# has no closed-range type); `Math.Clamp(value, min, max)` replaces `clamp`, and `Math.Max(80, maxWords * 10)` models `characterCap`; keep the prompt as a C# raw string literal or concatenation with no newline; bind the settings page `NumberBox` controls with `Minimum` and `Maximum` set from the ranges and a `TextBox` with `AcceptsReturn` for the prompt; persist under `Windows.Storage.ApplicationData` or the daemon equivalent using the same seven key names.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/SummaryPreferenceDTOs.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The app and the daemon read one file for defaults, ranges and keys.
**Rationale**: Both sides compile against the same constants, so the settings panel and the summarizer cannot drift and "Reset to Defaults" lands where a never-configured daemon already sits.
**Approved**: pending

**Decision**: A prompt that drops `{maxWords}` is sent as written, with no sentence appended.
**Rationale**: An explicit prompt is more predictable than a hidden sentence appended behind the user's back (the doc comment on `maxWordsPlaceholder` makes this choice); the cost is that the model is not told the cap, which still trims the reply.
**Approved**: pending

**Decision**: The word cap is told to the model and enforced on the reply.
**Rationale**: A small local model routinely overruns the cap (the doc comment on `SummaryDefaults.maxWords` says so), so asking is not enough.
**Approved**: pending

**Decision**: `characterCap(maxWords:)` is `max(80, maxWords * 10)` and lives with the defaults.
**Rationale**: The startup purge must use the same number (the doc comment on `characterCap(maxWords:)` says so); two literals could drift and a purge below the cap wipes fresh titles and re-queues them forever.
**Approved**: pending

**Decision**: Out-of-range values clamp to the nearest bound instead of being rejected.
**Rationale**: An out-of-range value (the doc comment on `SummaryLimits` names both cases) from an older app or a hand-rolled HTTP POST should land on a sane number rather than wedge the summarizer.
**Approved**: pending

**Decision**: The per-run and timeout defaults are gentle: 5 sessions per pass and 60 seconds per completion.
**Rationale**: A backlog should drain gently instead of bursting model calls, and a local model on a cold load needs more time than a cloud API.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

separation-of-concerns passes: the file holds constants, the range bounds, one clamp and one cap function; reading the settings table, the XPC push and the reply cleaning live in `SummaryPrefs`, `StenographerSummaryPrefsPush` and `DaemonSessionSummarizer`. unit-test-coverage passes: `SummaryPreferenceDTOsConformanceTests` calls `clamp` and `characterCap` directly and asserts the range bounds, key string, default prompt and defaults (vectors 001 to 003 and 010 to 015); vectors 004 to 009 are covered by the daemon tests named in the vectors file. data-minimization passes: `detailChars` caps how much of each event's detail leaves the session for the prompt, and the source names that cap as data minimization.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (SummaryPreferenceDTOsConformanceTests.swift, 9 of 15 vectors; 004-009 already covered by daemon tests in other targets); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Named HTTP as the current push transport, added the verbatim default prompt, restated the purge threshold drift as a known non-conformance, rewrote the decision rationales and moved the panel description to the AppKit note. |

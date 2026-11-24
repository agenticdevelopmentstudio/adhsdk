---
id: 211ef664-01fc-45d5-996b-1a0a4167a748
title: "Partner Step Template"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Fills curly-brace placeholders in job step commands in one pass, quoting values as single shell words for terminal steps and leaving prompt values as written."
platforms:
  - swift
  - macos
tags:
  - foundation
  - partner
  - templating
  - shell-quoting
depends-on:
  - 79810488-c613-4f9b-af2a-4ba9d8ee1c26
related: []
references: []
approved-by: ""
approved-date: ""
---

# Partner Step Template

## Overview

`PartnerStepTemplate` has two functions named `fill` and one helper. The *command fill* is `fill(_ command: String, values: [String: String]) -> String`; the *step fill* is `fill(_ steps: [PartnerJobStep], values: [String: String]) -> [PartnerJobStep]`; the helper is `shellQuoted(_ value: String) -> String`. Together they fill `{key}` placeholders in the commands of a partner job's steps. A terminal step is a shell command line, so each value goes in as one shell word; a Claude step is a prompt, so its values are typed as written. A value that itself contains a placeholder is never substituted again, which matters because a value such as a commit subject is written by someone else.

## Behavioral Requirements

- **placeholder-syntax**: A placeholder MUST be an opening brace, one or more word characters (the ICU `\w` class used by Swift's `NSRegularExpression`: Unicode letters, marks and decimal digits, plus underscore and other connector punctuation, so `{café}` is a placeholder; a port MUST use this same class, not an ASCII-only one) and a closing brace; `{}` and `{two words}` are not placeholders.
- **fill-known**: The command fill MUST replace each placeholder whose key has a value with that value.
- **unknown-stays**: A placeholder whose key has no value MUST stay in the output exactly as written.
- **one-pass**: Substitution MUST be one pass over the original command; a value MUST NOT be scanned for placeholders, so a value containing `{key}` appears as written.
- **text-between-preserved**: All text outside replaced placeholders MUST be copied unchanged.
- **terminal-quoting**: The step fill MUST quote every value with `shellQuoted` before filling a step whose environment is `terminal`.
- **claude-unquoted**: The step fill MUST fill a step whose environment is `claude` with the values as written.
- **steps-keep-fields**: The step fill MUST return one step per input step, in order, changing only `command`; `name`, `environment` and `condition` MUST be unchanged.
- **plain-word-unquoted**: `shellQuoted` MUST return a value as written when it is not empty and every character is an ASCII letter, an ASCII numeral, or one of `_ - . / : @ + ,`.
- **otherwise-single-quoted**: `shellQuoted` MUST otherwise return the value wrapped in single quotes, with each single quote in the value written as the four characters quote, backslash, quote, quote.
- **empty-is-quoted**: `shellQuoted` MUST return two single quotes for an empty value, so it stays one word.
- **no-equals-no-tilde**: `shellQuoted` MUST quote a value containing `=` or `~`.
- **empty-values-unchanged**: The command fill MUST return a command with every placeholder as written when `values` is empty.
- **hostile-values-inert**: The step fill MUST deliver a value containing `{key}`, a single quote, `$`, a backtick or a space to a terminal step as one shell word with no expansion, and MUST deliver it verbatim to a Claude step.
## Appearance

Not applicable — this is a pure text-substitution helper, not a visual component.

## States

Not applicable — this is a pure text-substitution helper, not a visual component.

## Accessibility

Not applicable — this is a pure text-substitution helper, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-step-template-001 | fill-known, unknown-stays | Command `/code-review high {sha} {nope}`, values `sha` = `abc`. | `/code-review high abc {nope}` (test: fillReplacesKnownAndKeepsUnknown). |
| partner-step-template-002 | one-pass | Command `{subject} {sha}`, values `subject` = `fix {sha} {nope}`, `sha` = `abc`. | `fix {sha} {nope} abc` (test: fillIsOnePassSoAValueIsNeverReSubstituted). |
| partner-step-template-003 | terminal-quoting, claude-unquoted | A terminal step `claude --model {model}` and a Claude step `/code-review {model}`, values `model` = `opus[1m]`. | Commands become `claude --model 'opus[1m]'` and `/code-review opus[1m]` (test: aTerminalStepQuotesItsValuesAndAClaudeStepDoesNot). |
| partner-step-template-004 | plain-word-unquoted, terminal-quoting | The same terminal step with `model` = `claude-opus-5-5`. | `claude --model claude-opus-5-5`, unquoted (test: aTerminalStepQuotesItsValuesAndAClaudeStepDoesNot). |
| partner-step-template-005 | otherwise-single-quoted | `shellQuoted` of the value `it's`. | `'it'\''s'` (test: aTerminalStepQuotesItsValuesAndAClaudeStepDoesNot, line `shellQuoted("it's")`). |
| partner-step-template-006 | no-equals-no-tilde | `shellQuoted` of the value `=ls`. | `'=ls'` (test: aTerminalStepQuotesItsValuesAndAClaudeStepDoesNot). |
| partner-step-template-007 | empty-is-quoted | `shellQuoted` of the empty string. | `''` (test: PartnerStepTemplateConformanceTests). |
| partner-step-template-008 | placeholder-syntax | Command `{} {a b} {c}`, values `c` = `x`. | `{} {a b} x` (test: PartnerStepTemplateConformanceTests). |
| partner-step-template-009 | steps-keep-fields | One terminal step with `name` `open`, `condition` `when-idle` and command `echo {x}`, values `x` = `1`. | One step with `name` `open`, environment `terminal`, `condition` `when-idle` and command `echo 1` (test: PartnerStepTemplateConformanceTests). |
| partner-step-template-010 | text-between-preserved | Command `a {x} b {x} c`, values `x` = `1`. | `a 1 b 1 c` (test: PartnerStepTemplateConformanceTests). |
| partner-step-template-011 | placeholder-syntax | Command `{café}`, values `café` = `x`. | `x` (test: PartnerStepTemplateConformanceTests). |
| partner-step-template-012 | no-equals-no-tilde | `shellQuoted` of `~/x`. | `'~/x'` (test: PartnerStepTemplateConformanceTests). |
| partner-step-template-013 | terminal-quoting, claude-unquoted | One terminal step `echo {v}` and one Claude step `say {v}` in the same list, values `v` = `a b`. | Commands `echo 'a b'` and `say a b` (test: PartnerStepTemplateConformanceTests). |
| partner-step-template-014 | empty-values-unchanged | Command `x {a} {b}`, empty `values`. | `x {a} {b}` (test: PartnerStepTemplateConformanceTests). |
## Edge Cases

- **Null / empty input**: An empty command returns an empty string; an empty `values` leaves every placeholder as written (see `#requirements/empty-values-unchanged`); an empty step list returns an empty list; an empty value fills as nothing in a Claude step and as two single quotes in a terminal step.
- **Boundary values**: Adjacent placeholders such as `{a}{b}` are both filled; a placeholder at the very start or end of the command is filled; the key is word characters only, so `{a-b}` is not a placeholder and stays as written.
- **Concurrent access**: Both functions are pure over their arguments; the compiled expression is a shared immutable constant, so concurrent callers are safe.
- **Error states**: The functions cannot fail. The placeholder expression is a constant created with a forced `try!` (the source disables the lint rule on that line); it is fixed, so it cannot fail at run time.
- **Offline / disconnected state**: Not applicable: the type performs no network or file access.
- **Cancellation**: Not applicable: every function is synchronous.
- **Hostile values**: A value containing `{key}`, a single quote, `$`, backticks or spaces is covered by `#requirements/hostile-values-inert`; that is the reason for one-pass substitution and for quoting.

## Configuration

None: the type reads no environment variable or settings key. The caller supplies the command (or steps) and a dictionary of string values; the placeholder pattern and the plain-word character set are fixed constants.

## Deep Linking

Not applicable: it defines no URL scheme, route or navigation destination.

## Localization

Not applicable: the source contains no user-facing string literal.

## Accessibility Options

Not applicable: it presents no UI, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source contains no feature-flag reference.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data handled**: Step commands and the values filled into them, which can include text written by others such as a commit subject or author.
- **Storage**: None; it persists nothing.
- **Transmission**: None; the caller decides what runs the resulting command.
- **Retention**: None beyond the lifetime of the strings the caller holds.

## Logging

Not applicable: the source calls no logging API.

## Platform Notes

- **SwiftUI**: Source is `Core/Partner/PartnerStepTemplate.swift`, a caseless `enum` importing only `Foundation`; it uses `NSRegularExpression` with a raw-string pattern and `NSString` ranges (UTF-16 offsets). Nothing is UI-specific.
- **Compose**: Top-level functions on `String` using a `Regex` of an escaped brace, one or more word characters in a capture group and an escaped brace, with `Regex.replace` and a lambda, which is one pass for free; Kotlin's word class is ASCII by default.
- **React/Web**: `String.prototype.replace` with a global regular expression and a replacer function is one pass; look the key up with `Object.hasOwn` rather than `in`, so keys such as `constructor` are not found on the prototype. The quoting is for a POSIX or zsh shell run by Node.
- **AppKit / UIKit**: Identical to the SwiftUI note; the file is UI-framework-agnostic.
- **WinUI 3**: A static class using `Regex.Replace` with a `MatchEvaluator` that returns `values[key]` when `TryGetValue` succeeds and `match.Value` otherwise; the evaluator form is one pass. .NET's word class matches Unicode letters unless `RegexOptions.ECMAScript` is given, so pin the character class to match the Swift one you are porting. `shellQuoted` targets zsh and POSIX shells; a Windows terminal step run by `cmd.exe` or PowerShell needs its own quoting rule, which this source does not define.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Partner/PartnerStepTemplate.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Substitution is one pass over the original command.
**Rationale**: A value can contain text written by someone else (a commit subject). Scanning values again would let that text pull in other values or placeholders; a test pins it.
**Approved**: pending

**Decision**: Terminal steps quote values; Claude steps do not.
**Rationale**: A terminal step is a shell command line where an unquoted `opus[1m]` is a glob, while a Claude step is a prompt where quotes would show up as literal characters.
**Approved**: pending

**Decision**: A plain word is left unquoted.
**Rationale**: So that a command such as `claude --model opus` still reads naturally; only values with a character outside the plain set are quoted.
**Approved**: pending

**Decision**: `=` and `~` are outside the plain set.
**Rationale**: A leading `=` is zsh's command-path expansion and `~` expands to a home directory.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |

`separation-of-concerns` passes because the type only substitutes and quotes text; deciding what values to supply and running the command belong to the callers. `unit-test-coverage` passes: `PartnerModelsTests` covers vectors 001-006 and `PartnerStepTemplateConformanceTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Partner/PartnerStepTemplateConformanceTests.swift`) covers 007-014. `input-sanitization` is partial: values reach a terminal step as one quoted word, but a Claude-step prompt receives them as written by design, and the type is not a general sanitizer.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (PartnerStepTemplateConformanceTests.swift, 14 of 14 vectors; 001-006 already in PartnerModelsTests); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Spelled out both fill signatures, pinned the placeholder character class, made hostile-values and empty-values named requirements, gave literal vector outputs, added four vectors, downgraded unit-test-coverage to partial, and depends-on partner-job. |

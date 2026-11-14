---
id: 9c81ac1c-ee1e-45b1-824c-deee1850037c
title: "Shell Quoting"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Quotes words for a POSIX shell so each reaches the command as one argument, spelled like Python's shlex.quote, and joins words into a command line."
platforms:
  - swift
  - macos
tags:
  - foundation
  - process
  - shell
  - strings
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Shell Quoting

## Overview

Quoting for a POSIX shell, so a word reaches the command as exactly one argument whatever it holds. The spelling matches Python's `shlex.quote`, so the Python helpers and this code write identical strings for the same path in `settings.json` and status-line entries. `ShellQuoting` is a caseless `enum` of three static functions: `quote(_:)` always quotes, `quoteIfNeeded(_:)` leaves a plain word readable, and `commandLine(_:)` joins words into one command line.

## Behavioral Requirements

- **quote-wraps-in-single-quotes**: `quote(word)` MUST return the word wrapped in one leading and one trailing single quote, including when the word is plain or empty.
- **quote-escapes-single-quote**: `quote(word)` MUST write each embedded single quote as the five characters `'"'"'` (close the quote, a double-quoted single quote, reopen the quote).
- **quote-replaces-literally**: `quote(word)` MUST find embedded single quotes by literal code-point comparison, not by grapheme comparison, so a single quote followed by a combining mark (U+0301) is still escaped. The source comment records that the default grapheme comparison would leave it unescaped and break the quoting.
- **quote-preserves-other-characters**: `quote(word)` MUST leave every character other than the single quote unchanged inside the quotes, including spaces, newlines and the combining mark itself.
- **plain-word-unchanged**: `quoteIfNeeded(word)` MUST return the word as is when it is non-empty and every Unicode scalar is one of `A-Z`, `a-z`, `0-9`, `_`, `@`, `%`, `+`, `=`, `:`, `,`, `.`, `/` or `-`.
- **empty-word-quoted**: `quoteIfNeeded("")` MUST return `''`, because an empty string is not in the plain class.
- **non-plain-word-quoted**: `quoteIfNeeded(word)` MUST return `quote(word)` when the word is empty or holds any scalar outside the plain class, including a space, a single quote and a non-ASCII letter.
- **plain-set-is-ascii-only**: The plain class MUST be tested per Unicode scalar against the listed ASCII characters, so a non-ASCII letter such as `é` is never plain.
- **command-line-joins-with-space**: `commandLine(words)` MUST return each word passed through `quoteIfNeeded(_:)`, joined by a single space, in the order given.
- **command-line-round-trips**: `commandLine(words)` MUST produce a string that a POSIX shell splits back into exactly the given words.
- **pure-functions**: Each function MUST depend only on its arguments, MUST NOT read the environment or a file, and MUST NOT run a process.
- **no-failure-path**: Each function MUST return a string for every input and MUST NOT throw.

## Appearance

Not applicable — this is a string-quoting function set, not a visual component.

## States

Not applicable — this is a stateless function set, not a visual component; it holds no runtime state.

## Accessibility

Not applicable — this is a string-quoting function set, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| shell-quoting-001 | empty-word-quoted | `quoteIfNeeded("")` | `''` (test: emptyWordIsQuoted). |
| shell-quoting-002 | plain-word-unchanged | `quoteIfNeeded("/usr/local/bin/steno-1.2")` | `/usr/local/bin/steno-1.2` (test: plainWordIsUnchanged). |
| shell-quoting-003 | quote-escapes-single-quote, non-plain-word-quoted | `quoteIfNeeded("it's")` | `'it'"'"'s'` (test: singleQuoteIsEscapedLikeShlex). |
| shell-quoting-004 | quote-replaces-literally | `quote("a'\u{301}b")` | `'a'"'"'\u{301}b'` (test: singleQuoteBeforeCombiningMarkIsEscaped). |
| shell-quoting-005 | non-plain-word-quoted | `quoteIfNeeded("a b")` | `'a b'` (test: spacesAreQuoted). |
| shell-quoting-006 | plain-set-is-ascii-only | `quoteIfNeeded("caf\u{e9}")` | `'caf\u{e9}'` (test: nonASCIILetterIsQuoted). |
| shell-quoting-007 | quote-wraps-in-single-quotes | `quote("plain")` | `'plain'` (test: quoteAlwaysQuotes). |
| shell-quoting-008 | command-line-joins-with-space, plain-word-unchanged, non-plain-word-quoted | `commandLine(["ls", "-la", "my dir"])` | `ls -la 'my dir'` (test: commandLineQuotesOnlyWordsThatNeedIt). |
| shell-quoting-009 | quote-escapes-single-quote | `quote("'")` | `''"'"''`: the opening quote, the escape, the closing quote (derived from the escape rule; no test beside the source). |
| shell-quoting-010 | command-line-joins-with-space | `commandLine([])` | The empty string (derived: joining no words yields no characters; no test beside the source). |

## Edge Cases

- **Null / empty input**: An empty word MUST become `''` from both `quote(_:)` and `quoteIfNeeded(_:)`; an empty word list MUST yield the empty string from `commandLine(_:)`.
- **Boundary values**: A word made only of single quotes MUST have each quote escaped, so `'` becomes `''"'"''`. A word one scalar outside the plain class, such as a trailing space, MUST be quoted whole, never partly.
- **Malformed input**: Any string is accepted; the functions do not validate. Characters special to a shell (`$`, backtick, `*`, `~`, `;`, newline) are not in the plain class, so `quoteIfNeeded(_:)` quotes them, and inside single quotes the shell does not expand them.
- **Unicode**: A single quote followed by a combining mark MUST still be escaped (see **quote-replaces-literally**). Non-ASCII letters are quoted, never passed bare.
- **Concurrent access**: The functions are pure and the plain character set is an immutable `private static let`, so concurrent calls from any thread do not interact.
- **Error states**: Not applicable: no function throws or returns an error value, and none touches the file system, network or a process.
- **Offline / disconnected state**: Not applicable: the functions perform no network access.
- **Cancellation and timeouts**: Not applicable: each call is a synchronous in-memory string transformation with no wait.

## Configuration

None — `ShellQuoting` reads no environment variable or settings key and has no parameter beyond the words passed in. The plain character class is a fixed constant, not configurable.

## Deep Linking

Not applicable: `ShellQuoting` defines no URL scheme, route or navigation destination.

## Localization

Not applicable: `ShellQuoting` contains no user-facing string.

## Accessibility Options

Not applicable: `ShellQuoting` presents no UI and responds to no display option.

## Feature Flags

Not applicable: `ShellQuoting` contains no feature-flag reference.

## Analytics

Not applicable: `ShellQuoting` contains no analytics call.

## Privacy

- **Data handled**: Only the words its caller passes in, which may be file paths.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the strings the caller holds.

## Logging

Not applicable: `ShellQuoting` calls no logging API.

## Platform Notes

- **SwiftUI**: The source file `Core/Process/ShellQuoting.swift` imports only `Foundation` and is UI-independent, so a SwiftUI host calls it unchanged. It is a public caseless `enum`. The literal replace is `replacingOccurrences(of:with:options: .literal)`; the plain test is `CharacterSet.contains` over `unicodeScalars`.
- **Compose**: Top-level functions over `String` and `List<String>`. Replace the single quote with `replace("'", "'\"'\"'")` (Kotlin's `String.replace` works on characters, so the combining-mark pitfall does not arise), and test plainness with a regex over `[A-Za-z0-9_@%+=:,./-]+`.
- **React/Web**: Pure functions over strings. Use `String.prototype.replaceAll("'", "'\"'\"'")` (code-unit based, so no grapheme pitfall) and a `/^[A-Za-z0-9_@%+=:,./-]+$/` test for the plain class; join with `words.map(quoteIfNeeded).join(" ")`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic and only the embedding application differs, never this contract.
- **WinUI 3**: A static class over `string` and `IEnumerable<string>`. Use `string.Replace("'", "'\"'\"'")` (ordinal for the string overload without a culture argument) and a `Regex` or a `HashSet<char>` for the plain class; `string.Join(" ", words.Select(QuoteIfNeeded))`. The output targets a POSIX shell, not `cmd.exe` or PowerShell, so a port that launches a Windows shell needs different quoting; this contract covers POSIX only.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Process/ShellQuoting.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The spelling matches Python's `shlex.quote`: single quotes, embedded quote written as `'"'"'`, and a plain class of `[A-Za-z0-9_@%+=:,./-]`.
**Rationale**: The source states that the Python helpers and this code write identical strings for the same path in `settings.json` and status-line entries, so a file written by either side compares equal.
**Approved**: pending

**Decision**: The embedded-quote replace is `.literal`, not the default grapheme comparison.
**Rationale**: The source comment records that the default compares by grapheme, so a single quote followed by a combining mark would go unescaped and break the quoting.
**Approved**: pending

**Decision**: The plain test is per Unicode scalar against an ASCII-only set.
**Rationale**: A non-ASCII letter is quoted rather than passed bare (test: nonASCIILetterIsQuoted). The source gives no further reason; the class follows `shlex.quote`, which the source names as the spelling to match.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |

`separation-of-concerns` passes because the type only turns words into shell-safe strings; running a command and choosing the words are the caller's. `unit-test-coverage` passes because `ShellQuotingTests` covers the empty word, a plain word, an embedded single quote, a single quote before a combining mark, spaces, a non-ASCII letter, `quote(_:)` on a plain word and `commandLine(_:)`. `input-sanitization` passes because every character outside the plain class is quoted and every embedded single quote is escaped. `unicode-support` passes because the replace is literal and the plain test is per scalar, both covered by tests.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |

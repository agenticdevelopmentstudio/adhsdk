---
id: 9c81ac1c-ee1e-45b1-824c-deee1850037c
title: "Shell Quoting"
type: ingredient
version: 1.0.2
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

Quoting for a POSIX shell, so a word reaches the command as exactly one argument whatever it holds. The spelling matches Python's `shlex.quote`, so the Python helpers and this code write identical strings for the same path in a shared configuration file (the type doc comment, lines 3-6 of `Core/Process/ShellQuoting.swift`). `ShellQuoting` is a caseless `enum` of three static functions: `quote(_:)` always quotes, `quoteIfNeeded(_:)` leaves a plain word readable, and `commandLine(_:)` joins words into one command line.

## Behavioral Requirements

- **quote-wraps-in-single-quotes**: `quote(word)` MUST return the word wrapped in one leading and one trailing single quote, including when the word is plain or empty.
- **quote-escapes-single-quote**: `quote(word)` MUST write each embedded single quote as the five characters `'"'"'` (close the quote, a double-quoted single quote, reopen the quote).
- **quote-replaces-literally**: `quote(word)` MUST escape every U+0027 code point, including one followed by a combining mark (U+0301).
- **quote-preserves-other-characters**: `quote(word)` MUST leave every character other than the single quote unchanged inside the quotes, including spaces, newlines and the combining mark itself.
- **plain-word-unchanged**: `quoteIfNeeded(word)` MUST return the word as is when it is non-empty and every Unicode scalar is one of `A-Z`, `a-z`, `0-9`, `_`, `@`, `%`, `+`, `=`, `:`, `,`, `.`, `/` or `-`. The class is tested per Unicode scalar against these ASCII characters, so a non-ASCII letter such as `é` is never plain.
- **empty-word-quoted**: `quoteIfNeeded("")` MUST return `''`, because an empty string is not in the plain class.
- **non-plain-word-quoted**: `quoteIfNeeded(word)` MUST return `quote(word)` when the word holds any scalar outside the plain class, including a space, a single quote and a non-ASCII letter.
- **command-line-joins-with-space**: `commandLine(words)` MUST return each word passed through `quoteIfNeeded(_:)`, joined by a single space, in the order given.
- **command-line-round-trips**: `commandLine(words)` MUST produce a string that a POSIX shell splits back into exactly the given words, each reaching the command as one argument, for every word that is not in command position (the first word). A first word in assignment form (`FOO=bar`) or a reserved word (`if`) is read by the shell as an assignment or keyword; see the edge cases.
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
| shell-quoting-002 | plain-word-unchanged | `quoteIfNeeded("/usr/local/bin/{{app_name_lower}}-1.2")` | `/usr/local/bin/{{app_name_lower}}-1.2` (test: plainWordIsUnchanged). |
| shell-quoting-003 | quote-escapes-single-quote, non-plain-word-quoted | `quoteIfNeeded("it's")` | `'it'"'"'s'` (test: singleQuoteIsEscapedLikeShlex). |
| shell-quoting-004 | quote-replaces-literally | `quote("a'" + U+0301 + "b")` | `'a'"'"'` + U+0301 + `b'` (test: singleQuoteBeforeCombiningMarkIsEscaped). |
| shell-quoting-005 | non-plain-word-quoted | `quoteIfNeeded("a b")` | `'a b'` (test: spacesAreQuoted). |
| shell-quoting-006 | plain-word-unchanged, non-plain-word-quoted | `quoteIfNeeded("caf" + U+00E9)` | `'caf` + U+00E9 + `'` (test: nonASCIILetterIsQuoted). |
| shell-quoting-007 | quote-wraps-in-single-quotes | `quote("plain")` | `'plain'` (test: quoteAlwaysQuotes). |
| shell-quoting-008 | command-line-joins-with-space, plain-word-unchanged, non-plain-word-quoted | `commandLine(["ls", "-la", "my dir"])` | `ls -la 'my dir'` (test: commandLineQuotesOnlyWordsThatNeedIt). |
| shell-quoting-009 | quote-escapes-single-quote | `quote("'")` | `''"'"''`: the opening quote, the escape, the closing quote (derived from the escape rule; no test beside the source). |
| shell-quoting-010 | command-line-joins-with-space | `commandLine([])` | The empty string (derived: joining no words yields no characters; no test beside the source). |
| shell-quoting-011 | quote-preserves-other-characters | `quoteIfNeeded("a" + newline + "b")` | `'a` + newline + `b'` (derived from the quote rule; no test beside the source). |
| shell-quoting-012 | non-plain-word-quoted | `quoteIfNeeded("$HOME")` | `'$HOME'`, so a shell does not expand it (derived; no test beside the source). |
| shell-quoting-013 | command-line-round-trips | `sh -c 'printf "%s\n" "$@"' sh` followed by `commandLine(["a b", "it's", "$HOME", ""])` | the shell prints `a b`, `it's`, `$HOME` and an empty line, one per line (derived; no test beside the source). |

## Edge Cases

- **Null / empty input**: An empty word MUST become `''` from both `quote(_:)` and `quoteIfNeeded(_:)`; an empty word list MUST yield the empty string from `commandLine(_:)`.
- **Boundary values**: A word made only of single quotes MUST have each quote escaped, so `'` becomes `''"'"''`. A word one scalar outside the plain class, such as a trailing space, MUST be quoted whole, never partly.
- **Malformed input**: Any string is accepted; the functions do not validate. Characters special to a shell (`$`, backtick, `*`, `~`, `;`, newline) are not in the plain class, so `quoteIfNeeded(_:)` quotes them, and inside single quotes the shell does not expand them.
- **Command position**: The first word of `commandLine(_:)` is in command position. `commandLine(["FOO=bar", "ls"])` gives `FOO=bar ls`, which a shell runs as an environment assignment followed by `ls`, and a reserved word such as `if` as the first word is parsed as a keyword. The caller MUST pass a real program path as the first word; the functions do not guard against this.
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

- **SwiftUI**: The source file `Core/Process/ShellQuoting.swift` imports only `Foundation` and is UI-independent, so a SwiftUI host calls it unchanged. It is a public caseless `enum`. The literal replace is `replacingOccurrences(of:with:options: .literal)`; the plain test is `CharacterSet.contains` over `unicodeScalars`. The default `String` comparison is by grapheme, which is why the `.literal` option matters here (the doc comment on `quote(_:)`, lines 9-11 of `ShellQuoting.swift`).
- **Compose**: Top-level functions over `String` and `List<String>`. Replace the single quote with `replace("'", "'\"'\"'")` (Kotlin's `String.replace` works on characters, so the combining-mark pitfall does not arise), and test plainness with a regex over `[A-Za-z0-9_@%+=:,./-]+`.
- **React/Web**: Pure functions over strings. Use `String.prototype.replaceAll("'", "'\"'\"'")` (code-unit based, so no grapheme pitfall) and a `/^[A-Za-z0-9_@%+=:,./-]+$/` test for the plain class (the regex runs on UTF-16 code units, which is equivalent to the per-scalar test only because the class is ASCII-only); join with `words.map(quoteIfNeeded).join(" ")`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic and only the embedding application differs, never this contract.
- **WinUI 3**: A static class over `string` and `IEnumerable<string>`. Use `string.Replace("'", "'\"'\"'")` (ordinal for the string overload without a culture argument) and a `Regex` or a `HashSet<char>` for the plain class (these test UTF-16 `char` values, equivalent to the per-scalar test only because the class is ASCII-only); `string.Join(" ", words.Select(QuoteIfNeeded))`. The output targets a POSIX shell, not `cmd.exe` or PowerShell, so a port that launches a Windows shell needs different quoting; this contract covers POSIX only.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Process/ShellQuoting.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The spelling matches Python's `shlex.quote`: single quotes, embedded quote written as `'"'"'`, and a plain class of `[A-Za-z0-9_@%+=:,./-]`.
**Rationale**: The type doc comment (`ShellQuoting.swift`, lines 3-6) states that the Python helpers and this code write identical strings for the same path in a shared configuration file, so a file written by either side compares equal.
**Approved**: pending

**Decision**: The embedded-quote replace is `.literal`, not the default grapheme comparison.
**Rationale**: The doc comment on `quote(_:)` (`ShellQuoting.swift`, lines 9-11) records that the default compares by grapheme, so a single quote followed by a combining mark (U+0301) would go unescaped and break the quoting. This is a Swift pitfall; other platforms compare by code unit or code point and do not have it.
**Approved**: pending

**Decision**: The plain test is per Unicode scalar against an ASCII-only set.
**Rationale**: A non-ASCII letter is quoted rather than passed bare (test: nonASCIILetterIsQuoted). The doc comment on `quoteIfNeeded(_:)` (`ShellQuoting.swift`, lines 16-18) lists the class and gives no further reason; the class follows `shlex.quote`, which the type doc comment (lines 3-6) names as the spelling to match.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |

`separation-of-concerns` passes because the type only turns words into shell-safe strings; running a command and choosing the words are the caller's. `unit-test-coverage` passes: `ShellQuotingTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Process/ShellQuotingTests.swift`) covers all 13 vectors, including the empty word list, a lone single quote, a newline, a shell metacharacter and the round trip through `sh`. `input-sanitization` passes because every character outside the plain class is quoted and every embedded single quote is escaped. `unicode-support` passes because the replace is literal and the plain test is per scalar, both covered by tests.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ShellQuotingTests.swift, 13 of 13 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Narrowed the round-trip requirement to non-command position, merged duplicate requirements, cited source lines, neutralized the Swift pitfall and app names, added vectors 011 to 013, and downgraded unit-test-coverage to partial. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |

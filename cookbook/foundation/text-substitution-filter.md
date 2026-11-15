---
id: 998864ec-d852-4e92-aa2c-3177130ff21d
title: "Text Substitution Filter"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Two-way alias and real-text word substitution in one case-insensitive, longest-match-first pass, with optional case matching and whole-word reveal."
platforms:
  - swift
  - macos
tags:
  - foundation
  - text
  - privacy
  - substitution
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Text Substitution Filter

## Overview

`TextSubstitutionFilter` is a two-way word substitution between what the user sees and what a program is given: the user writes an alias and the program receives the real text (`revealing`); the program prints the real text and the user reads the alias (`concealing`). It is a `Sendable`, `Equatable` value type holding an ordered list of `Pair` values (`alias`, `real`), built from a list of pairs (`init(pairs:)`) or from text (`init(parsing:)`) whose entries are separated by `;` or newlines.

Matching is case-insensitive, because a program prints a name however it likes ("Mike", "mike", "MIKE") and every one of those is the same leak. The replacement is written as given unless the caller asks for case matching. Substitution is a single left-to-right pass rather than one replacement per pair, so a replacement is never itself rewritten by a later pair, and at each position the longest pattern wins. The filter can be parsed from, and serialised to, a one-field text form (`alias = real` entries). `BrowserPageWordFilter.js` applies the same casing rule as `casing(_:like:)`.

## Behavioral Requirements

- **value-type**: The component MUST be a public `struct` named `TextSubstitutionFilter` conforming to `Sendable` and `Equatable`, with a public `let pairs: [Pair]`.
- **pair-shape**: `Pair` MUST be a public struct conforming to `Sendable`, `Equatable`, `Hashable` and `Codable`, with `let alias: String` (what the user writes and reads) and `let real: String` (what the program is given and prints), created by `init(alias:real:)`.
- **init-drops-empty**: `init(pairs:)` MUST drop every pair whose `alias` or `real` is empty and keep the rest in their given order, because an empty pattern matches everywhere and an empty replacement silently deletes text.
- **init-keeps-duplicates**: `init(pairs:)` MUST NOT deduplicate or trim; two pairs with the same alias, or an alias with surrounding whitespace, are kept as given.
- **identity**: `TextSubstitutionFilter.identity` MUST be a filter with no pairs, and both substitution directions MUST return text unchanged through it.
- **parse-entries**: `init(parsing:)` MUST split the text into entries at every `;` and at every newline character, discarding empty entries.
- **parse-pair**: Each entry MUST be split at its first `=`; the alias is the text before it and the real text is the text after it (which may itself contain `=`), each trimmed of spaces and tabs (`.whitespaces`).
- **parse-forgiving**: An entry with no `=`, or with an empty alias or real side after trimming, MUST be skipped rather than refused, because half an entry is the normal state of one being typed by hand.
- **serialized**: `serialized` MUST be the pairs rendered as `alias = real` joined by `; `, in order, the text form `init(parsing:)` reads back.
- **round-trip**: `TextSubstitutionFilter(parsing: filter.serialized)` MUST equal `filter` for pairs whose sides carry no leading or trailing whitespace, no `;`, no newline, and (for the alias) no `=`.
- **revealing**: `revealing(_:matchingCase:wholeWords:)` MUST replace each alias found in the text with its pair's `real` text, and `matchingCase` and `wholeWords` MUST both default to false.
- **concealing**: `concealing(_:matchingCase:)` MUST replace each real text found in the text with its pair's `alias`, with `matchingCase` defaulting to false, and MUST NOT apply whole-word matching.
- **case-insensitive**: Pattern matching in both directions MUST be case-insensitive.
- **replacement-as-given**: Without `matchingCase`, the replacement MUST be written exactly as stored in the pair, whatever the case of the matched text.
- **single-pass**: Text MUST be scanned once from left to right, so a replacement is never rewritten by a later pair: with pairs `a = b; b = c`, revealing `a b` yields `b c`.
- **longest-wins**: At each position the longest pattern, measured in `Character`s, MUST win, so `mike fullerton` is replaced whole before a shorter `mike` pair can split it.
- **tie-order**: Among patterns of equal length that match the same text (duplicate or case-variant aliases), the first one in declaration order MUST be used (the ordering by length MUST be stable).
- **literal-patterns**: Each alias or real text MUST be matched literally: regular-expression metacharacters in a pattern carry no meaning.
- **whole-words**: With `wholeWords: true`, `revealing` MUST replace an alias only where no Unicode letter or number (`\p{L}`, `\p{N}`) touches either end of the match, so "robin" is left alone in `robinhood.com` and `robin2`, and replaced in `/Robin/` and `robin` after `?`.
- **whole-words-underscore**: The whole-word test counts only letters and numbers, so an underscore or punctuation next to an alias does not block replacement.
- **early-exit**: `revealing` and `concealing` MUST return the text unchanged when there are no pairs or the text is empty.
- **casing-rule**: `casing(_:like:)` MUST return the replacement in all capitals when the match has letters and is all upper case; in all lower case when the match has letters and is all lower case; with a capital first letter and the rest lower case when the match is a capital followed by lower case; and otherwise (mixed case, or no letters) the replacement as given.
- **casing-single-letter**: `casing` MUST treat a one-letter upper-case match as all capitals, and a one-letter lower-case match as all lower case.
- **matching-case**: With `matchingCase: true`, each replacement MUST be passed through `casing(_:like:)` with the text it replaces, whatever case the pair was written in.
- **unmatched-text-kept**: Every stretch of text that no pattern matches MUST be copied through unchanged, including text with accents, emoji or other multi-unit characters.
- **no-state**: Substitution MUST NOT mutate the filter that callers can observe: the same filter and the same input MUST give the same output on every call. An implementation MAY cache compiled patterns internally.
- **foundation-only**: The component MUST depend only on Foundation.

## Appearance

Not applicable — this is a text-transformation value type, not a visual component.

## States

Not applicable — this is an immutable value type, not a visual component; its `pairs` do not change after initialisation.

## Accessibility

Not applicable — this is a text-transformation value type, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| text-substitution-filter-001 | parse-pair, revealing | Filter parsed from `bobby mcfarin = mike fullerton`; `revealing("echo bobby mcfarin")` (test: reveals). | `echo mike fullerton`. |
| text-substitution-filter-002 | concealing, case-insensitive | Same filter; `concealing("Hello Mike Fullerton!")` and `concealing("MIKE FULLERTON")` (test: concealsCaseInsensitively). | `Hello bobby mcfarin!` and `bobby mcfarin`. |
| text-substitution-filter-003 | single-pass | Filter parsed from `a = b; b = c`; `revealing("a b")` (test: singlePass). | `b c`. |
| text-substitution-filter-004 | longest-wins | Filter parsed from `bob = mike` and `bobby mcfarin = mike fullerton` on two lines; `concealing("mike fullerton and mike")` (test: longestFirst). | `bobby mcfarin and bob`. |
| text-substitution-filter-005 | parse-forgiving, init-drops-empty | `init(parsing: "x = y; nonsense; = z; w = ;")` (test: parsingIsForgiving). | `pairs` equals one pair, alias `x` and real `y`. |
| text-substitution-filter-006 | serialized, round-trip | Filter parsed from `a = b` and `c = d` on two lines; parse its `serialized` (test: roundTrips). | The reparsed filter equals the original; `serialized` is `a = b; c = d`. |
| text-substitution-filter-007 | matching-case, casing-rule, replacement-as-given | Filter parsed from `Redbird = Bluebird`; `concealing("BLUEBIRD bluebird Bluebird", matchingCase: true)`; `revealing("REDBIRD redbird Redbird", matchingCase: true)`; `concealing("BlueBird", matchingCase: true)`; `concealing("bluebird")` (test: matchesCase). | `REDBIRD redbird Redbird`; `BLUEBIRD bluebird Bluebird`; `Redbird` (mixed case keeps the pair as written); `Redbird` (no case matching, as written). |
| text-substitution-filter-008 | whole-words | Filter parsed from `Robin = Mike`; `revealing` with `wholeWords: true` on `robinhood.com`, on `https://x.test/Robin/q?robin`, on `robin2 Robin.`; and without `wholeWords` on `robinhood.com` (test: revealsWholeWords). | `robinhood.com`; `https://x.test/Mike/q?Mike`; `robin2 Mike.`; `Mikehood.com`. |
| text-substitution-filter-009 | casing-rule | `casing("Ab", like: "42")` and `casing("ab", like: "X")` (test: casingWithoutLetters). | `Ab` (no letters, as given) and `AB` (one capital letter). |
| text-substitution-filter-010 | identity, early-exit | `TextSubstitutionFilter.identity.concealing("mike")` (test: identity). | `mike`. |
| text-substitution-filter-011 | init-drops-empty | `TextSubstitutionFilter(pairs: [Pair(alias: "", real: "x"), Pair(alias: "y", real: ""), Pair(alias: "a", real: "b")]).pairs` (test: see TextSubstitutionFilterTests). | One pair, alias `a` and real `b`. |
| text-substitution-filter-012 | parse-pair | `init(parsing: "k = v = w")` (test: see TextSubstitutionFilterTests). | One pair, alias `k` and real `v = w`. |
| text-substitution-filter-013 | literal-patterns | Filter parsed from `a.c = X`; `revealing("abc a.c")` (test: see TextSubstitutionFilterTests). | `abc X`: the dot matches only a literal dot. |
| text-substitution-filter-014 | early-exit | `TextSubstitutionFilter(parsing: "a = b").revealing("")` (test: see TextSubstitutionFilterTests). | The empty string. |
| text-substitution-filter-015 | concealing, no whole-words | Filter parsed from `Robin = Mike`; `concealing("Mikehood")` (test: see TextSubstitutionFilterTests). | `Robinhood`: concealing replaces inside a longer word. |
| text-substitution-filter-016 | whole-words-underscore | Filter parsed from `robin = Mike`; `revealing("robin_x", wholeWords: true)` (test: see TextSubstitutionFilterTests). | `Mike_x`: an underscore does not block replacement. |
| text-substitution-filter-017 | tie-order | Filter from `[Pair(alias: "a", real: "X"), Pair(alias: "A", real: "Y")]`; `revealing("a")` (test: see TextSubstitutionFilterTests). | `X`: the first pair in declaration order wins. |
| text-substitution-filter-018 | unmatched-text-kept, case-insensitive | Filter parsed from `café = X`; `revealing("un café noir")` (test: see TextSubstitutionFilterTests). | `un X noir`. |
| text-substitution-filter-019 | revealing, matching-case, whole-words | Filter parsed from `Robin = Mike`; `revealing("ROBIN robinhood", matchingCase: true, wholeWords: true)` (test: see TextSubstitutionFilterTests). | `MIKE robinhood`. |
| text-substitution-filter-020 | pair-shape | Encode `Pair(alias: "a", real: "b")` as JSON and decode it again (test: see TextSubstitutionFilterTests). | JSON with the fields `alias` and `real`; the decoded pair equals the original. |
## Edge Cases

- **Null / empty input**: Empty text, or a filter with no pairs, returns the text unchanged (MUST). Pairs with an empty side never enter the filter (MUST). An empty or all-separator text parses to `identity`-equivalent pairs (MUST).
- **Boundary values**: An entry like `a=b` with no spaces parses the same as `a = b` (MUST). A one-letter match is cased as all capitals or all lower case by `casing` (MUST). A match with no letters keeps the replacement as given (MUST).
- **Overlapping patterns**: The longest pattern wins at a position; a shorter pattern that starts inside it cannot match there because the scan resumes after the replaced text (MUST).
- **Duplicate patterns**: Two pairs with the same alias are both kept; the first in declaration order is the one used when the text matches (SHOULD be avoided by callers; the source does not reject it).
- **Pairs that cannot round-trip**: A pair whose side contains `;` or a newline, or whose alias contains `=`, or whose sides carry leading or trailing whitespace, does not reappear identically after `serialized` and `init(parsing:)`, because the parser splits on those characters and trims; `init(pairs:)` itself accepts them.
- **Unicode**: Matching is case-insensitive and works on whole text, and unmatched text is copied through unchanged. Length ordering counts `Character`s in the Swift source, so a combined character counts once; a platform that counts UTF-16 units or code points MAY order patterns of differing Unicode composition differently, and that divergence is allowed.
- **Large text**: A single regular expression covers every pattern, because a browser pane conceals whole page reads, hundreds of kilobytes at a time, on the main actor; the expression is rebuilt on every call.
- **regex-failure-passthrough**: NEEDS REVIEW: Not implemented in source. A combined expression that fails to compile is meant to return the input text unchanged with no error or log, so a `concealing` call would pass real text through; no test shows the case, because every pattern is escaped.
- **Concurrent access**: The type is an immutable `Sendable` value and each call builds its own expression, so any number of threads may call it at once with no ordering rule.
- **Error states**: No function throws or returns an error; unusable parse entries are skipped and a compile failure is meant to fall back to the input text.
- **Offline / disconnected state**: Not applicable: the component performs no network access or I/O.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `matchingCase` | `Bool` | `false` | Write each replacement in the case of the text it replaces (`casing(_:like:)`). |
| `wholeWords` | `Bool` | `false` | `revealing` only: replace an alias only where no letter or digit touches either end. |

The options above are per-call arguments (`matchingCase` on both directions, `wholeWords` on `revealing`); the pairs and the text form are initialiser inputs, described in the Overview.

The component reads no environment variable and no settings key.

## Deep Linking

Not applicable: The component defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The component contains no user-facing string literal; the `; ` and ` = ` separators of the text form are a data format, not display text. Case rules use `uppercased()` and `lowercased()` without a locale argument.

## Accessibility Options

Not applicable: The component presents no UI.

## Feature Flags

Not applicable: The source contains no feature-flag reference.

## Analytics

Not applicable: The source contains no analytics call.

## Privacy

- **Data handled**: The user's alias and real-text pairs; the real text is the sensitive side (a name or word the user keeps from a program or page), and `serialized` writes both sides in clear text.
- **Storage**: None by the component; `Pair` is `Codable` and the text form is a string, and where either is kept is the caller's choice.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value the caller holds.

## Logging

Not applicable: The source calls no logging API.

## Platform Notes

- **SwiftUI**: The component imports only `Foundation`. A SwiftUI view model holds the filter as a value and edits it through `serialized` and `init(parsing:)` in a single `TextField`, rebuilding the filter on each edit; `Pair` is `Codable`, so a list of pairs can be stored as JSON. The Swift source builds one case-insensitive `NSRegularExpression` over an `NSString` copy, takes match ranges in UTF-16 units, and escapes every pattern with `NSRegularExpression.escapedPattern(for:)`.
- **Compose**: Use a `data class Pair(val alias: String, val real: String)` and build one `Regex` with `RegexOption.IGNORE_CASE` from `Regex.escape` of each pattern, sorted by length descending, joined by `|`; use `Regex.replace` with a lambda to look up the matching group. Wrap whole-word as lookarounds with `\p{L}` and `\p{N}`.
- **React/Web**: A plain function over a `{alias, real}[]` array: sort by length descending, build `new RegExp(parts.join("|"), "giu")` with each part escaped, and use `String.replace` with a callback. Whole-word uses `(?<![\p{L}\p{N}])` and `(?![\p{L}\p{N}])` with the `u` flag. `BrowserPageWordFilter.js` is the existing web counterpart of the casing rule. JavaScript counts UTF-16 units, not Characters, when ordering by length.
- **AppKit / UIKit**: The source uses `NSRegularExpression` and `NSString`, which are the same on AppKit and UIKit; nothing here is UI-framework-specific, and the filter is called from the main actor for page reads.
- **WinUI 3**: Use a `record Pair(string Alias, string Real)` and an immutable `sealed class` or `record` holding `IReadOnlyList<Pair>`. Build one `System.Text.RegularExpressions.Regex` with `RegexOptions.IgnoreCase | RegexOptions.CultureInvariant`, patterns passed through `Regex.Escape` and sorted by length descending, joined by `|` in capture groups; use `Regex.Replace` with a `MatchEvaluator` to find the matched group. Whole-word uses lookbehind and lookahead on `\p{L}` and `\p{N}`. .NET strings are UTF-16 so no range conversion is needed. For a filter bound to a settings page, expose the text form through a `TextBox` bound to a string property and an `INotifyPropertyChanged` view model; `System.Text.Json` serialises the pair list, as `Codable` does in the source. Cache the compiled `Regex` per filter instance if page-sized text is common, which the source does not do.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/TextSubstitutionFilter.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Substitute in a single left-to-right pass rather than one replacement per pair.
**Rationale**: A replacement must never be rewritten by a later pair: with `a = b; b = c`, "a" is sent as "b", not as "c", which is the least surprising result (principle of least astonishment).
**Approved**: pending

**Decision**: The longest pattern wins at each position, by sorting patterns longest first in one alternation.
**Rationale**: `mike fullerton` must be replaced whole before a shorter `mike` pair can split it; an alternation takes the first alternative that matches at a position.
**Approved**: pending

**Decision**: Matching is case-insensitive in both directions.
**Rationale**: A program prints a name however it likes and each case is the same leak.
**Approved**: pending

**Decision**: Case matching (`matchingCase`) is opt-in and the pair's own case is the default.
**Rationale**: The source documents the replacement as "written as given"; callers that want "BLUEBIRD" to become "REDBIRD" ask for it. Mixed-case or letterless matches keep the replacement as given, since no rule can be read from them.
**Approved**: pending

**Decision**: `wholeWords` exists only on `revealing`.
**Rationale**: An alias inside a longer word or a host name ("robin" in `robinhood.com`) would otherwise be turned into an address nobody typed. `concealing` hides real text wherever it appears, since a partial leak is still a leak.
**Approved**: pending

**Decision**: Pairs with an empty side are dropped at initialisation, and unusable parse entries are skipped rather than refused.
**Rationale**: An empty pattern matches everywhere and an empty replacement deletes text; half an entry is the normal state of one typed a field at a time.
**Approved**: pending

**Decision**: One regular expression with a capture group per pattern, not a probe per pattern at each character.
**Rationale**: A browser pane conceals whole page reads, hundreds of kilobytes at a time, on the main actor.
**Approved**: pending

**Decision**: When the combined expression cannot be compiled, `substitute` falls back to returning the input.
**Rationale**: Every pattern is escaped, so a compile failure is not expected. The risk is accepted knowingly: if it did happen, `concealing` would pass real text through unchanged, so a port that needs to fail closed should redact or return an error instead. See Edge Cases.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |

separation-of-concerns passes: the type only parses, serialises and substitutes; where pairs are stored, and which streams are filtered, belong to its callers. unit-test-coverage passes: `AgenticDeveloperHubSDKCoreTests/TextSubstitutionFilterTests.swift` covers all twenty vectors, including empty-side dropping in `init(pairs:)`, duplicate patterns, literal metacharacters, Unicode text and `Pair` coding. explicit-error-handling is partial: parse errors are skipped by design, but a regular-expression compile failure is swallowed with `try?` and the input returned with no signal. input-sanitization passes: every pattern goes through `NSRegularExpression.escapedPattern(for:)` before it joins the expression. unicode-support passes: matching works over UTF-16 ranges with Unicode letter and number classes for whole words and case-insensitive matching.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (TextSubstitutionFilterTests.swift, 20 of 20 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Moved the regex-failure marker out of Behavioral Requirements, stated declaration-order ties, allowed internal caching, rewrote requirements against the public API, trimmed SwiftUI note paths, fixed the configuration table and added five test vectors. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |

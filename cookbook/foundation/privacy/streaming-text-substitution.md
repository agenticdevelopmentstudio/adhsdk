---
id: 88d2aa75-3a9c-404a-8d3f-7db520d1bec1
title: "Streaming Text Substitution"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Byte-stream word substitution that holds a possible partial match across reads so a split word is never leaked, matching ASCII case-insensitively."
platforms:
  - swift
  - macos
tags:
  - foundation
  - privacy
  - strings
depends-on:
  - 998864ec-d852-4e92-aa2c-3177130ff21d
related:
  - 89df0861-df4c-4839-9da2-bf65910ad5dd
references: []
approved-by: ""
approved-date: ""
---

# Streaming Text Substitution

## Overview

`StreamingTextSubstitution` applies a `TextSubstitutionFilter` to a byte stream that arrives in pieces: keystrokes on their way to a shell, or output on its way to the screen, where a word can be split across two reads. It works on bytes, not text, because a terminal stream is not guaranteed to be valid UTF-8 at any boundary. Patterns match as UTF-8 bytes, ASCII letters case-insensitively and every other byte exactly. A run of bytes that could still become a match is held rather than emitted, because emitting half a name and matching the other half later is the leak the type exists to stop. Held bytes come out when the stream diverges from every pattern, when a pattern completes, or when the owner calls `flush()`. It is a mutable value type with no I/O and no timer; the owner decides when to flush.

## Behavioral Requirements

- **value-type**: The type MUST be a `Sendable` struct created with `init(filter:direction:)`, with no timer, thread or I/O of its own.
- **direction-revealing**: With `Direction.revealing`, each pair's alias MUST be the pattern and its real text the replacement, which is what goes to the program.
- **direction-concealing**: With `Direction.concealing`, each pair's real text MUST be the pattern and its alias the replacement, which is what comes back to the user.
- **byte-matching**: Patterns MUST be matched as their UTF-8 bytes, and the stream MUST NOT be decoded to text.
- **ascii-case-fold**: Bytes 0x41 to 0x5A (ASCII `A` to `Z`) MUST compare equal to their lowercase forms in both pattern and stream, and every other byte MUST compare exactly, so non-ASCII letters are never case-folded.
- **replacement-as-given**: A replacement MUST be written exactly as stored in the filter, never recased to the matched text.
- **longest-first**: At each position the longest pattern that matches MUST win, so `mike fullerton` is taken whole before `mike`.
- **single-pass**: A replacement MUST NOT be scanned again, so with pairs that chain (`a` to `b`, `b` to `c`) one pass sends `a` as `b`.
- **no-word-boundary**: A match MUST NOT depend on the bytes around it; a pattern inside a longer word is replaced.
- **pass-through-bytes**: Any byte that is not the first byte of a pattern (compared lowercased) MUST be emitted unchanged without further matching.
- **hold-partial**: When the unconsumed bytes from a position are a proper prefix (ASCII case-insensitive) of some pattern, `feed` MUST hold the bytes from that position to the end and emit only what precedes it.
- **hold-over-shorter-match**: A held prefix MUST be held even when a shorter pattern already matches there, because a longer pattern may still complete (`mike` is held when `mike fullerton` is a pattern).
- **hold-released**: Held bytes MUST be rescanned together with the next `feed`, so a completed pattern is replaced and a diverging stream releases the held bytes unchanged.
- **emit-complete-match**: A pattern that matches completely and cannot be extended by a longer pattern MUST be replaced and emitted in the same `feed` call, without waiting for more input.
- **flush**: `flush()` MUST emit everything held, replacing whatever already matches completely and passing a partial match through unchanged, and MUST leave nothing held.
- **flush-empty**: `flush()` with nothing held MUST return an empty array.
- **is-holding**: `isHolding` MUST be true exactly when bytes are held awaiting more input.
- **no-patterns**: When the filter has no pairs, `feed` MUST return the held bytes followed by the new bytes unchanged and hold nothing.
- **order-preserved**: Output bytes MUST come out in input order, and every input byte MUST be either emitted unchanged, replaced as part of a match, or held; none is dropped.
- **binary-safe**: Bytes that are not valid UTF-8 (a lone 0xFF, half a character at the end of a read) MUST pass through unchanged unless they match a pattern byte for byte.
- **generic-input**: `feed` MUST accept any `Sequence` of `UInt8`.
- **hold-bound**: The held run MUST be shorter than the longest pattern, because only a proper prefix is held.
- **empty-sides-dropped**: The stream MAY assume every pattern is non-empty, because `TextSubstitutionFilter.init(pairs:)` drops pairs with an empty alias or real before the stream sees them; the stream does not check this itself.
- **pattern-order-ties**: When two patterns have equal length, a port MAY try them in any order. Two such patterns can both match at one position only when they differ in ASCII case alone, and the source does not specify which replacement wins.
- **no-retry-no-errors**: No operation MUST throw or return an error.
- **owner-flushes-output**: The type has no timer, so the owner MUST call `flush()` on the output side after a moment of quiet, or a prompt that ends in a pattern's prefix never appears.
- **concurrency**: The type is a value with no internal locking; an instance MUST be used by one caller at a time.

## Appearance

Not applicable — this is a byte-stream transformer, not a visual component.

## States

Not applicable — this is a byte-stream transformer, not a visual component. Its runtime state is the held bytes, described under Behavioral Requirements (nothing held, or a partial match held).

## Accessibility

Not applicable — this is a byte-stream transformer, not a visual component.

## Conformance Test Vectors

The vectors are derived from the source and covered by `StreamingTextSubstitutionConformanceTests.swift`. The vectors are derived from the source, and they are the tests to write for this type. Unless stated, the filter has one pair, alias `robin` and real `mike`, direction `concealing`; `feed` takes ASCII bytes and returns the bytes shown as text.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| streaming-text-substitution-001 | emit-complete-match, direction-concealing | `feed("hello mike")` | `hello robin`, `isHolding` false. |
| streaming-text-substitution-002 | hold-partial, hold-released | `feed("hello mi")`, then `feed("ke!")` | First call returns `hello ` with `isHolding` true; second returns `robin!` with `isHolding` false. |
| streaming-text-substitution-003 | hold-released | `feed("mi")`, then `feed("x")` | First returns empty, second returns `mix`. |
| streaming-text-substitution-004 | flush, is-holding | `feed("mik")`, then `flush()` | `feed` returns empty with `isHolding` true; `flush` returns `mik` and `isHolding` is false. |
| streaming-text-substitution-005 | ascii-case-fold, replacement-as-given | `feed("MIKE Mike")` | `robin robin`. |
| streaming-text-substitution-006 | direction-revealing | Same filter, direction `revealing`; `feed("robin")` | `mike`. |
| streaming-text-substitution-007 | longest-first | Pairs (`rob`, `mike`) and (`robert`, `mike fullerton`), concealing; `feed("mike fullerton")` | `robert`. |
| streaming-text-substitution-008 | hold-over-shorter-match, flush | Same two pairs; `feed("mike")`, then `flush()` | `feed` returns empty and holds; `flush` returns `rob`. |
| streaming-text-substitution-009 | single-pass | Pairs (`b`, `a`) and (`c`, `b`), concealing; `feed("ab")` | `bc`, not `cc`. |
| streaming-text-substitution-010 | ascii-case-fold | Pair (`x`, `É`), concealing; `feed` of the bytes of `é` (0xC3 0xA9), then of `É` (0xC3 0x89) | The first call returns its bytes unchanged; the second returns `x`. |
| streaming-text-substitution-011 | binary-safe, no-patterns | Identity filter; `feed([0xFF, 0x6D])` | `[0xFF, 0x6D]`, `isHolding` false. |
| streaming-text-substitution-012 | binary-safe, hold-partial | Filter as default; `feed([0xFF, 0x6D])` | `[0xFF]` with `m` held; `isHolding` true. |
| streaming-text-substitution-013 | no-word-boundary | `feed("mimike")` | `mirobin`. |
| streaming-text-substitution-014 | flush-empty | A new instance; `flush()` | Empty array. |
| streaming-text-substitution-015 | order-preserved | `feed("a mike b")` | `a robin b`. |
| streaming-text-substitution-016 | no-patterns | Identity filter; `feed("abc")` | `abc`, `isHolding` false. |
| streaming-text-substitution-017 | generic-input | `feed` of a `[UInt8]` array, then of an `ArraySlice<UInt8>`, each holding bytes of `mi` and `ke` respectively | Both calls compile and run; the second returns `robin`. |
| streaming-text-substitution-018 | hold-bound | Pair (`robert`, `mike fullerton`), concealing; `feed("mike fullert")` | Returns empty; the held run is 12 bytes, shorter than the 14-byte pattern. |
| streaming-text-substitution-019 | pass-through-bytes | `feed("hello world")` | `hello world`, `isHolding` false; no byte is held because none is the first byte of a pattern (`m`). |
| streaming-text-substitution-020 | hold-released, hold-over-shorter-match | Pairs (`rob`, `mike`) and (`robert`, `mike fullerton`), concealing; `feed("mike x")` | `rob x`, `isHolding` false. |
| streaming-text-substitution-021 | flush, emit-complete-match | Same two pairs; `feed("mike fu")`, then `flush()` | `feed` returns empty and holds; `flush` returns `rob fu`. |
## Edge Cases

- **Null / empty input**: `feed` with an empty sequence rescans the held bytes and emits any part that can no longer become a match, keeping the rest held; with nothing held it returns empty (MUST). With no pairs the input is returned unchanged (MUST).
- **Boundary values**: A pattern split at every byte position across reads is still replaced once. The held run is at most the longest pattern length minus one (MUST). A one-byte pattern is replaced immediately and never held unless a longer pattern begins with the same byte, in which case that byte is held like any other prefix.
- **Concurrent access**: A value type with no synchronisation. A port MUST confine an instance to one caller at a time.
- **Error states**: Nothing throws; invalid UTF-8 is passed through untouched (MUST).
- **Held bytes at stream end**: Bytes still held when no more input will come are not released by the type; the owner MUST call `flush()` or the final partial match stays held; An owner that flushes only one side leaves the other side's partial match held until the next input or an explicit flush. `flush` passes a partial prefix through unchanged.
- **Non-ASCII patterns**: Words with non-ASCII letters match only in exact case, unlike the filter's `String` matching which folds case for every script; this is deliberate (see Design Decisions).
- **Partial prefix then divergence**: Held `mik` followed by `x` is rescanned as `mikx`: the first-byte rule is applied again from the start, and the bytes come out as `mikx` unless a different pattern starts inside them.
- **Overlapping patterns**: With `mike` and `ike`, `mike` is consumed whole before `ike` is looked at; the replaced text is not rescanned.
- **Offline / disconnected state**: Not applicable: the type performs no network access.
- **Cancellation**: Not applicable: each call completes synchronously and there is no cancel call.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `filter` | `TextSubstitutionFilter` | none (required) | The alias and real pairs; pairs with an empty side are already dropped by the filter. |
| `direction` | `Direction` | none (required) | `revealing` (alias to real, toward the program) or `concealing` (real to alias, back to the user). |

## Deep Linking

Not applicable: the type defines no URL scheme, route or navigation destination.

## Localization

Not applicable: the type contains no user-facing string; it transforms bytes it is given.

## Accessibility Options

Not applicable: the type presents no UI and responds to no accessibility display option.

## Feature Flags

Not applicable: the type contains no feature-flag reference.

## Analytics

Not applicable: the type contains no analytics call.

## Privacy

- **Data collected**: The bytes of a terminal stream (keystrokes and program output), which can include secrets, and the privacy words in the filter.
- **Storage**: In memory only: the patterns and the held bytes of the current instance; nothing is persisted.
- **Transmission**: None; the type performs no network access. Its output goes to the caller.
- **Retention**: Held bytes live until the next `feed` or `flush`; the patterns live as long as the instance.
- **Purpose**: Concealing real words in output and revealing aliases in input, so a half-matched word is never emitted before its other half arrives.

## Logging

Not applicable: the type calls no logging API; the stream and the words are never written to a log.

## Platform Notes

- **SwiftUI**: It is a public `Sendable` struct with a nested `Direction`, importing only `Foundation`. A SwiftUI host would hold one instance per direction and flush the output side from a timer, after a moment of quiet.
- **Compose**: A class over `ByteArray` or a reusable `ByteArrayOutputStream`; a one-shot flush uses a `CoroutineScope` delay cancelled and re-armed on each read. Keep each instance on one dispatcher.
- **React/Web**: Use `Uint8Array` input and output with a `TextEncoder` for pattern bytes; keep one instance per stream and flush with `setTimeout` after a quiet period. Do not decode with `TextDecoder` before matching, for the same reason the source avoids it.
- **AppKit / UIKit**: The same type serves both. The owner flushes the output instance with a one-shot `Timer` while `isHolding`, and flushes both instances before replacing the filter.
- **WinUI 3**: Implement as a class over `byte[]` with `List<byte>` or `Span<byte>` for the held run and patterns from `Encoding.UTF8.GetBytes`; return `byte[]` from `Feed` and `Flush` and expose `IsHolding` as a property. Pattern lookup can use a `HashSet<byte>` for first bytes and a `List` sorted by `Length` descending (use `OrderByDescending`, which is stable). Do not use `string` or `Decoder` to match; use `ReadOnlySpan<byte>` sequence comparisons with an ASCII fold (`b | 0x20` for 0x41 to 0x5A). Drive the quiet-time flush with a `DispatcherQueueTimer` (`IsRepeating = false`) on the UI thread, or `System.Threading.Timer` guarded by a lock if the stream is read off the UI thread; the type itself has no locking.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Privacy/StreamingTextSubstitution.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Work on bytes, not text.
**Rationale**: The type's doc comment says a terminal stream is not guaranteed to be valid UTF-8 at any boundary, and decoding it to match would corrupt binary or a half character at the end of a read.
**Approved**: pending

**Decision**: Fold case only for ASCII letters; every other byte matches exactly.
**Rationale**: The type's doc comment says a stream cannot afford Unicode case folding across a read boundary and names typed at a shell are overwhelmingly ASCII; this is narrower than the filter's own `String` matching, a known deviation.
**Approved**: pending

**Decision**: Hold any run that could still become a match, even when a shorter pattern already matches.
**Rationale**: Emitting half a name and matching the other half later is the leak the type exists to stop; holding costs a short delay that the owner bounds with `flush()`.
**Approved**: pending

**Decision**: The type has no timer; the owner calls `flush()` after a moment of quiet.
**Rationale**: The doc comment on `StreamingTextSubstitution` says the owner's output side flushes after a moment of quiet, so a prompt ending in a prefix of a word is not kept off the screen forever; keeping the clock outside keeps the type pure and testable.
**Approved**: pending

**Decision**: Longest pattern first, replacements never rescanned, and no whole-word or case-matching options.
**Rationale**: The same left-to-right rules as `TextSubstitutionFilter` (a replacement is never rewritten by a later pair, the longer name wins), but without that filter's `wholeWords` and `matchingCase` options, which the stream does not implement.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | privacy-and-data |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | partial | internationalization |

Separation of concerns passes: the type matches and holds bytes while the pair list, word storage and flush timing live in the filter, the store and the terminal view. Unit-test coverage passes: `StreamingTextSubstitutionConformanceTests.swift` (suite `StreamingTextSubstitutionTests`) covers all 21 vectors. No PII in logs passes because the type calls no logging API. Unicode support is partial: bytes pass through unchanged and non-ASCII patterns match byte for byte, but only ASCII letters fold case, so a non-ASCII word typed in another case is not replaced.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (StreamingTextSubstitutionConformanceTests.swift, 21 of 21 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Made requirement keywords normative, moved terminal-view details out, set tie order to MAY, cited doc comments, added five vectors, and linked the filter and terminal view. |

---
id: de98aa67-83a3-41d1-907f-86713a7a6e10
title: "Sessions"
type: ingredient
version: 1.1.0
status: review
language: en
created: 2026-11-21
modified: 2026-11-21
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The Sessions namespace for session daemon wire types, its VisibleText scalar allowlist, and Stenographer's billing settings key prefix."
platforms:
  - swift
  - macos
tags:
  - foundation
  - sessions
  - dto
  - wire
depends-on: []
related:
  - e8286557-84ee-4f45-b78c-f1d184c51a37
  - 94bac7a5-3fc6-463d-86d1-7c59350cd7cb
  - fcbf09d9-5555-4278-9940-2be920de49d3
  - c5231579-d9c0-412d-8ae0-4c9bfb7937d3
  - 3f1efb26-3dfb-4e6c-bbbc-32609151ce78
  - dfdb871e-bca1-45a7-a64d-9ab6af0c0917
  - ed610aa4-2717-4242-a8b9-c4616377dbd9
references: []
approved-by: ""
approved-date: ""
---

# Sessions

## Overview

This ingredient covers the three files in `Core/Sessions/Wire/` that are not record families: the `Sessions` namespace itself, the `Sessions.VisibleText` character allowlist, and the `Sessions.StenographerBilling` settings key prefix. All three import only Foundation and are compiled into the `AgenticDeveloperHubSDKCore` framework (the `apple-core` tier, above only the Foundation-only `AgenticDeveloperHubSDK` tier and below `Database`), so the daemon side (the `Database` tier's `Database/Daemon` code) and every client can name them without importing each other.

**`Sessions`** (`Sessions.swift`) is `public enum Sessions {}`: an empty, caseless enum that exists only as a namespace. Its doc comment states the contract: "The session daemon's wire types: what a session daemon's routes return and its clients decode. They were `StenographerXPCProtocol`'s DTOs, and keep their names and fields inside this namespace, so a payload encoded by the old daemon decodes here unchanged." The namespace declares no members; every wire type is added by a sibling file through an `extension Sessions { ... }` block:

- `StatusLineDTOs.swift`: the usage, status-line and credential records ([adhsdk.ingredient.foundation.sessions.wire.status-line-dt-os](cookbook:94bac7a5-3fc6-463d-86d1-7c59350cd7cb)).
- `InsightsDTOs.swift` and `GraphSnapshotDTO.swift`: the insights and graph records ([adhsdk.ingredient.foundation.sessions.wire.insights-dt-os](cookbook:fcbf09d9-5555-4278-9940-2be920de49d3)).
- `AccountRouterDTOs.swift`: the account router records ([adhsdk.ingredient.foundation.sessions.wire.account-router-dt-os](cookbook:c5231579-d9c0-412d-8ae0-4c9bfb7937d3)).
- `ClaudeAccountRequestDTOs.swift` and `ClaudeAccountTokenDTOs.swift`: the saved-account requests and token states ([adhsdk.ingredient.foundation.sessions.wire.claude-account-request-dt-os](cookbook:3f1efb26-3dfb-4e6c-bbbc-32609151ce78)).
- `ModelRouterDTOs.swift` and `ModelRouterTemplates.swift`: the model router records and templates ([adhsdk.ingredient.foundation.sessions.wire.model-router-dt-os](cookbook:dfdb871e-bca1-45a7-a64d-9ab6af0c0917)).

**`Sessions.VisibleText`** (`VisibleText.swift`) decides "Which characters may reach a terminal, a log line or a stored label as-is." It is an allowlist over Unicode scalars, `isVisible(_:)`, and a filter, `visible(_:)`, that deletes every scalar the allowlist refuses. The account router uses both: `AccountRouterLog.scrub` filters with `isVisible` before it redacts secrets, and `DaemonDatabase.insertRouterExchange` passes the requested, routed and served model ids, the provider and the stop reason through `visible` before storing them. Model router template names use a different, looser denylist, `ModelRouterTemplateValidation.isRefusedInName`, as the doc comment notes.

**`Sessions.StenographerBilling`** (`StenographerBillingSettings.swift`) holds one constant, `settingsKeyPrefix = "stenographer_billing_"`: "Stenographer's half of the shared billing feature: the one value both of its processes must agree on." The app writes its billing knobs under this prefix and the daemon reads its settings table under it; the key names built from the prefix (`BillingSettingsKeys(prefix:)`) and the billing logic live in [adhsdk.ingredient.foundation.billing.billing-dt-os](cookbook:ed610aa4-2717-4242-a8b9-c4616377dbd9). `LegacySessionImporter.SourceKind.billingSettingsKeyPrefix` returns this constant for a `stenographerd` source, so the importer knows which settings rows of an old Stenographer database are billing knobs.

Use the namespace when adding a type that a session daemon route returns or a client of that route decodes; the JSON spelling those types are written in is [adhsdk.ingredient.foundation.stenographer.stenographer-wire](cookbook:e8286557-84ee-4f45-b78c-f1d184c51a37), not this file. Use `VisibleText` for any text from a client or an upstream that is about to reach a terminal, a log line or a stored label.

## Behavioral Requirements

### Sessions namespace

- **namespace-name**: The namespace MUST be a type named exactly `Sessions`, so every member is addressed as `Sessions.<TypeName>` (for example `Sessions.AccountQuotaReadingDTO`).
- **namespace-public**: The namespace MUST be visible to every module that links the framework declaring it.
- **namespace-uninhabited**: The namespace MUST have no cases and no initializer, so no value of type `Sessions` can be constructed.
- **namespace-stateless**: The namespace MUST hold no stored state of its own; its declaration has no static or instance properties.
- **namespace-empty-declaration**: The declaring file MUST declare no members inside the namespace; members MUST be added by extensions in sibling files.
- **wire-types-inside-namespace**: Every type a session daemon route returns or its clients decode MUST be declared inside the `Sessions` namespace.
- **legacy-names-kept**: Each wire type moved from `StenographerXPCProtocol` MUST keep the type name it had there.
- **legacy-fields-kept**: Each wire type moved from `StenographerXPCProtocol` MUST keep the field names it had there.
- **legacy-payload-decodes**: A payload encoded by the old Stenographer daemon MUST decode into the corresponding `Sessions` type unchanged.
- **foundation-only**: Each of the three files MUST depend on nothing but the platform's standard foundation library.
- **lowest-tier**: The namespace and its two helpers MUST live in the Core tier, below the `Database` tier, so the daemon composition and its clients can both reference them without a dependency on each other.

### VisibleText

- **visible-text-uninhabited**: `VisibleText` MUST be a caseless namespace nested in `Sessions` that exposes only static, stateless functions.
- **visible-letters**: `isVisible` MUST return true for a scalar whose general category is a letter: uppercase (Lu), lowercase (Ll), titlecase (Lt), modifier (Lm) or other (Lo), unless the default-ignorable rule refuses it.
- **visible-numbers**: `isVisible` MUST return true for a scalar whose general category is a number: decimal digit (Nd), letter number (Nl) or other number (No), unless the default-ignorable rule refuses it.
- **visible-punctuation**: `isVisible` MUST return true for a scalar whose general category is punctuation: connector (Pc), dash (Pd), open (Ps), close (Pe), initial quote (Pi), final quote (Pf) or other (Po), unless the default-ignorable rule refuses it.
- **visible-symbols**: `isVisible` MUST return true for a scalar whose general category is a symbol: math (Sm), currency (Sc), modifier (Sk) or other (So), unless the default-ignorable rule refuses it.
- **visible-space-separator**: `isVisible` MUST return true for a scalar whose general category is space separator (Zs), including U+0020 SPACE and U+00A0 NO-BREAK SPACE, unless the default-ignorable rule refuses it.
- **refuse-default-ignorable**: `isVisible` MUST return false for any scalar Unicode lists as Default_Ignorable_Code_Point, whatever its general category; this check MUST take precedence over the category allowlist (U+3164 HANGUL FILLER is category Lo and is refused).
- **refuse-controls**: `isVisible` MUST return false for control characters (Cc), including U+0000, U+0007, U+0009 TAB, U+000A LINE FEED, U+000D and U+001B ESCAPE.
- **refuse-format**: `isVisible` MUST return false for format characters (Cf), including U+200B ZERO WIDTH SPACE and the bidi controls such as U+202E.
- **refuse-marks**: `isVisible` MUST return false for every mark category: nonspacing (Mn), spacing combining (Mc) and enclosing (Me).
- **refuse-line-paragraph-separators**: `isVisible` MUST return false for U+2028 LINE SEPARATOR (Zl) and U+2029 PARAGRAPH SEPARATOR (Zp).
- **refuse-unassigned-private-use**: `isVisible` MUST return false for unassigned (Cn) and private-use (Co) code points.
- **refuse-by-default**: `isVisible` MUST return false for every general category not listed in the allowlist, so a category nobody enumerated is refused rather than admitted.
- **visible-deletes-refused**: `visible` MUST return its input with every scalar for which `isVisible` is false deleted, and MUST NOT substitute any replacement character for a deleted scalar.
- **visible-keeps-order**: `visible` MUST keep the scalars it does not delete in their original order and unchanged.
- **visible-no-normalization**: `visible` MUST NOT apply Unicode normalization; a precomposed letter such as U+00E9 is kept, while a base letter followed by a combining mark (U+0065 U+0301) loses the mark.
- **visible-idempotent**: Applying `visible` to its own output MUST return that output unchanged.
- **visible-pure**: `isVisible` and `visible` MUST be pure: their result MUST depend only on the argument, and they MUST have no side effects.

### StenographerBilling

- **stenographer-billing-uninhabited**: `StenographerBilling` MUST be a caseless namespace nested in `Sessions` whose only member is `settingsKeyPrefix`.
- **stenographer-billing-prefix-value**: `Sessions.StenographerBilling.settingsKeyPrefix` MUST be exactly the string `stenographer_billing_` (21 characters, trailing underscore included).
- **stenographer-billing-prefix-constant**: `settingsKeyPrefix` MUST be an immutable constant, so Stenographer's app and daemon read the same value.
- **stenographer-billing-key-shape**: A Stenographer billing settings key MUST be this prefix followed by the key name that `BillingSettingsKeys` appends (`stenographer_billing_idle_cutoff_minutes` for the idle cutoff).
- **stenographer-billing-legacy-source**: `LegacySessionImporter.SourceKind.stenographerd` MUST report this constant as its billing settings key prefix, distinct from the `billing_` default (`DaemonDatabase.defaultBillingSettingsKeyPrefix`) that `SourceKind.adkd` reports.

## Appearance

Not applicable — this is a namespace and two text and settings helpers for wire types, not a visual component.

## States

Not applicable — this is a namespace and two text and settings helpers for wire types, not a visual component.

## Accessibility

Not applicable — this is a namespace and two text and settings helpers for wire types, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| sessions-001 | namespace-name, namespace-public | A module that imports the Core framework references `Sessions.AccountQuotaReadingDTO` | Compiles; the reference resolves to the struct declared in `StatusLineDTOs.swift` (as `AccountRouterQuotaSource.swift` in the `Database` tier does with `extension Sessions.AccountQuotaReadingDTO`) |
| sessions-002 | namespace-uninhabited, visible-text-uninhabited, stenographer-billing-uninhabited | Source containing an expression that constructs a `Sessions`, `Sessions.VisibleText` or `Sessions.StenographerBilling` value (a call to the type name with no arguments) | Fails to compile: each enum has no cases and no initializer |
| sessions-003 | namespace-empty-declaration, namespace-stateless | Read the `Sessions` declaration in `Sessions.swift` | Zero cases, zero properties, zero methods, zero nested types inside its braces |
| sessions-004 | wire-types-inside-namespace | List every top-level declaration in the files of `Core/Sessions/Wire/` other than `Sessions.swift` | Every one is an `extension Sessions` block; no wire type is declared at file scope |
| sessions-005 | legacy-names-kept, legacy-fields-kept, legacy-payload-decodes | A JSON body the old Stenographer daemon encoded for a status-line record (for example one `rate_limit_snapshots` row), decoded with the shared wire decoder into the matching `Sessions` type | Decodes without error, every field present in the payload populated with the same value |
| sessions-006 | foundation-only | Inspect the imports of `Sessions.swift`, `VisibleText.swift` and `StenographerBillingSettings.swift` | Each has exactly one import: `Foundation` |
| sessions-007 | lowest-tier | Inspect which framework target compiles `Core/Sessions/Wire/` | `AgenticDeveloperHubSDKCore` (its `sources` path is `Core`); none of the three files imports a higher-tier framework |
| sessions-008 | visible-letters, visible-numbers, visible-punctuation, visible-symbols, visible-space-separator | `isVisible` on each of `A` (Lu), `a` (Ll), U+01C5 (Lt), U+02B0 (Lm), `東` (Lo), `7` (Nd), U+2160 (Nl), U+00BD (No), `_` (Pc), `-` (Pd), `(` (Ps), `)` (Pe), U+00AB (Pi), U+00BB (Pf), `!` (Po), `+` (Sm), `$` (Sc), `^` (Sk), U+2713 (So), U+0020 and U+00A0 (Zs) | `true` for every one |
| sessions-009 | refuse-controls, refuse-format, refuse-line-paragraph-separators | `isVisible` on U+0000, U+0007, U+0009, U+000A, U+000D, U+001B, U+0085, U+200B, U+202E, U+2028, U+2029 | `false` for every one |
| sessions-010 | refuse-marks, refuse-default-ignorable | `isVisible` on U+0301 (Mn), U+0903 (Mc), U+20DD (Me), U+FE0F (Mn, default-ignorable), U+034F (Mn, default-ignorable), U+E0100 (Mn, default-ignorable) | `false` for every one |
| sessions-011 | refuse-default-ignorable | `isVisible` on U+3164, U+115F, U+1160, U+FFA0 (all category Lo and default-ignorable) | `false` for every one, although their category is on the allowlist |
| sessions-012 | refuse-unassigned-private-use, refuse-by-default | `isVisible` on U+0378 (Cn) and U+E000 (Co) | `false` for both |
| sessions-013 | visible-deletes-refused, visible-keeps-order | `visible("claude-haiku\u{200B}-5-5")`, `visible("gpt\u{1B}[2J")`, `visible("P\u{202E}")`, `visible("end\u{0}_turn")`, `visible("claude-\u{1B}]52;c;eA==\u{07}x")` | `"claude-haiku-5-5"`, `"gpt[2J"`, `"P"`, `"end_turn"`, `"claude-]52;c;eA==x"` (`AccountRouterRecordTests.testInsertKeepsOnlyVisibleCharactersOfModelProviderAndStopReason`, which stores each through `insertRouterExchange`) |
| sessions-014 | visible-deletes-refused | `visible("one\ntwo\r\nthree\tfour\u{2029}five\u{0B}six")` | `"onetwothreefourfivesix"`, the filtering step behind `AccountRouterRecordTests.testScrubOutputIsAlwaysOneLine` |
| sessions-015 | visible-keeps-order, visible-no-normalization | `visible("café naïve \u{2713} 東京")` written with precomposed U+00E9 and U+00EF | Unchanged, as `AccountRouterRecordTests.testScrubDeletesEveryInvisibleScalarBeforeRedacting` asserts through `AccountRouterLog.scrub` ("visible text, accents included, is kept") |
| sessions-016 | visible-no-normalization, refuse-marks | `visible("e\u{0301}")` (decomposed é) | `"e"` |
| sessions-017 | visible-idempotent, visible-pure | `visible` applied twice to `"a\u{07}b\u{200B}c"`, from two threads at once | Both calls on both threads return `"abc"` |
| sessions-018 | visible-deletes-refused | `visible("")` and `visible("\u{07}\u{200B}\u{2028}")` | `""` for both |
| sessions-019 | stenographer-billing-prefix-value, stenographer-billing-prefix-constant | Read `Sessions.StenographerBilling.settingsKeyPrefix` | `"stenographer_billing_"` |
| sessions-020 | stenographer-billing-key-shape | `BillingSettingsKeys(prefix: Sessions.StenographerBilling.settingsKeyPrefix).idleCutoffMinutes` | `"stenographer_billing_idle_cutoff_minutes"` |
| sessions-021 | stenographer-billing-legacy-source | `LegacySessionImporter.SourceKind.stenographerd.billingSettingsKeyPrefix` and `.adkd.billingSettingsKeyPrefix` | `"stenographer_billing_"` and `"billing_"` |
| sessions-022 | stenographer-billing-legacy-source | A `stenographer.db` whose settings table holds `stenographer_billing_idle_cutoff_minutes = 30`, imported with `importStores(kind: .stenographerd, ...)` | The target holds the same value under its own prefix plus `idle_cutoff_minutes`, and no key matching `stenographer_billing_%` (`LegacySessionImporterTests.testBillingSettingsMoveToTheTargetPrefix`) |

No test beside the source exercises `Sessions.VisibleText` directly; vectors 013 to 015 are derived from the account router tests named in each row, which reach it through `insertRouterExchange` and `AccountRouterLog.scrub`. Vectors 001 to 004, 006, 007 and 019 are checked by the compiler or by reading the source, and vector 005 is the namespace doc comment's declared contract (see Compliance).

## Edge Cases

- **Null and empty input**: The namespace takes no input. `visible("")` MUST return `""`, and a string made only of refused scalars MUST also become `""` (vector 018); neither function has an optional parameter, so nil cannot reach them.
- **Boundary values**: U+0000 and the highest assigned and unassigned scalars are classified by the same rules as any other: U+0000 is a control and MUST be refused; a private-use scalar in planes 15 and 16 (U+F0000 to U+10FFFD) MUST be refused. Surrogates (U+D800 to U+DFFF) cannot occur, because a Swift `Unicode.Scalar` excludes them.
- **Default-ignorable letters**: A scalar such as U+3164 HANGUL FILLER whose category is on the allowlist but which Unicode lists as default-ignorable MUST be refused (vector 011); the default-ignorable check runs first.
- **No-break and other wide spaces**: U+00A0, U+2002 to U+200A and U+3000 are category Zs and not default-ignorable, so they MUST be kept; a caller that splits on U+0020 alone sees them as part of a word.
- **Emoji sequences**: Emoji scalars are category So and MUST be kept, but U+200D ZERO WIDTH JOINER (Cf, default-ignorable), the variation selectors U+FE0E and U+FE0F and U+20E3 COMBINING ENCLOSING KEYCAP (Me) MUST be deleted, so a ZWJ sequence or keycap renders afterwards as its separate component emoji and digits. Skin-tone modifiers (U+1F3FB to U+1F3FF, category Sk) and regional indicators (So) are kept.
- **Decomposed accents**: Text in a decomposed form loses its combining marks (vector 016); `visible` does no normalization first, so the same word in NFC and NFD gives different results.
- **Unicode version drift**: The category and default-ignorable tables are the ones the running Swift runtime ships. A code point assigned in a later Unicode version is unassigned (Cn) to an older runtime and MUST be refused there, so two runtimes MAY disagree on such a scalar.
- **Long input**: `visible` has no length limit and no truncation; it walks every scalar once. Truncation is the caller's job (`AccountRouterLog.scrub` cuts to 200 characters after filtering).
- **Concurrent access**: `Sessions`, `VisibleText` and `StenographerBilling` have no instances and no mutable state. `isVisible` and `visible` are static pure functions and MAY be called from any thread or actor at once; `settingsKeyPrefix` is an immutable `String` constant, safe to read from anywhere.
- **Error states**: No function here throws or returns an error. A payload that fails to decode fails in the member type's decoder, not here; the member recipes define those failures. A refused scalar is deleted, not reported.
- **Offline or disconnected state**: Not applicable; none of the three files performs I/O. Transport (the daemon's loopback HTTP routes) belongs to the route and client code that uses these types.
- **A payload from the old daemon**: A body encoded by the Stenographer daemon's XPC DTOs MUST decode into the same-named `Sessions` type with no translation layer (`legacy-payload-decodes`).
- **A type added outside the namespace**: A session daemon wire type declared at file scope violates `wire-types-inside-namespace`; it MUST be moved inside an `extension Sessions` block.
- **A rename of a moved type or field**: Renaming a type or field inherited from `StenographerXPCProtocol` breaks `legacy-names-kept` or `legacy-fields-kept`, and an old daemon's payload would no longer decode; such a rename MUST NOT be made while old payloads are still in circulation.
- **A change to the billing prefix**: Changing `settingsKeyPrefix` orphans every billing knob a Stenographer app has already written under `stenographer_billing_`, and the legacy importer would no longer recognise them in an old database; the value MUST NOT change.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Sessions.StenographerBilling.settingsKeyPrefix` | `String` (constant) | `"stenographer_billing_"` | The settings-table key prefix Stenographer's app writes its billing knobs under and its daemon reads them under; passed to `BillingSettingsKeys(prefix:)`. Not overridable. |
| `VisibleText` allowlist | fixed | Letters, numbers, punctuation, symbols, space separators, minus default-ignorable code points | Compiled in; no parameter, environment variable or settings key changes it. |

The namespace takes no parameters, reads no environment variables or settings keys, and has no injected dependencies.

## Deep Linking

Not applicable: none of the three files defines a URL or deep link; the routes the member types ride are session daemon API routes.

## Localization

Not applicable: the three files contain no user-facing strings. `stenographer_billing_` is a storage key, never shown to a user, and `VisibleText` classifies scalars by Unicode property, independent of locale.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: None. The namespace holds no data, `VisibleText` keeps nothing it filters, and `StenographerBilling` is a key prefix, not a value.
- **Storage**: None here. `VisibleText` is one of the defences in front of storage and logs: `AccountRouterLog.scrub` deletes invisible scalars first so none can split a secret token or hide its prefix from the redaction that follows, and `insertRouterExchange` stores only the visible characters of the model, provider and stop-reason columns. Redaction itself is `AccountRouterLog`'s, not this ingredient's.
- **Transmission**: None; no file here sends data anywhere.
- **Retention**: Not applicable; nothing is retained. Member types that carry identifying or secret data (for example `Sessions.ClaudeCredentialDTO`) state their privacy terms in their own recipes.

## Logging

Not applicable: this code makes no log calls. `VisibleText` prepares text for log lines written by its callers (`AccountRouterLog`), but logs nothing itself.

## Platform Notes

The `platforms` of this recipe are swift and macos; the notes for the other targets are porting guidance only.

- **SwiftUI**: `Core/Sessions/Wire/Sessions.swift` declares the caseless `public enum Sessions {}`; a caseless enum is the Swift idiom for a namespace because it cannot be instantiated. `VisibleText.swift` reads `Unicode.Scalar.properties.generalCategory` and `isDefaultIgnorableCodePoint`, which the Swift standard library answers from its own bundled Unicode tables (not ICU), and rebuilds the string through a `String.UnicodeScalarView`, so it deletes scalars rather than grapheme clusters. `StenographerBillingSettings.swift` is one `static let`. SwiftUI code names members as `Sessions.UsageRowsDTO` and so on; a client module that declares its own `Sessions` shadows this one and reaches the toolkit's as `AgenticDeveloperHubSDKCore.Sessions`.
- **Compose**: Use a Kotlin `object Sessions` with nested `object VisibleText` and `object StenographerBilling` (`const val SETTINGS_KEY_PREFIX = "stenographer_billing_"`). Iterate code points with `String.codePoints()` and classify with `Character.getType(cp)`, mapping its `UPPERCASE_LETTER`, `DECIMAL_DIGIT_NUMBER`, `CONNECTOR_PUNCTUATION`, `MATH_SYMBOL`, `SPACE_SEPARATOR` and the rest to the allowlist. The JDK has no default-ignorable query, so use ICU4J's `UCharacter.hasBinaryProperty(cp, UProperty.DEFAULT_IGNORABLE_CODE_POINT)` (or Android's `android.icu.lang.UCharacter`); rebuild the result with `StringBuilder.appendCodePoint`.
- **React/Web**: An ES module exporting `isVisible` and `visible`, imported as `import * as Sessions from "./sessions-wire"`. The allowlist maps onto one Unicode property regex with the `v` (or `u`) flag: keep `[\p{L}\p{N}\p{P}\p{S}\p{Zs}]` minus `\p{Default_Ignorable_Code_Point}`, written as a set subtraction under `v`, and filter with `Array.from(text)`, which iterates code points, not UTF-16 units. The prefix is an exported `const`. The engine's Unicode version decides the tables, as in Swift.
- **AppKit / UIKit**: Same as SwiftUI: all three are UI-framework agnostic and live in the Core framework, which an AppKit target links unchanged; the Core framework is built for macOS only, so a UIKit target would compile the three Foundation-only files into its own iOS target. Do not reach for `CharacterSet.controlCharacters` or `.illegalCharacters`; neither is an allowlist, and neither covers the default-ignorable letters.
- **WinUI 3**: Put a `public static class Sessions` (or a file-scoped `namespace AgenticDeveloperHub.Sessions;` with static classes inside) in a shared .NET class library that both the daemon (an ASP.NET Core minimal API host) and the WinUI 3 client reference, the counterpart of the Core tier. Port `VisibleText` as a `static class` with `bool IsVisible(Rune rune)` and `string Visible(string text)`: enumerate with `text.EnumerateRunes()`, classify with `Rune.GetUnicodeCategory(rune)` against the same `UnicodeCategory` members (`UppercaseLetter` to `OtherLetter`, `DecimalDigitNumber`, `LetterNumber`, `OtherNumber`, the seven punctuation members, the four symbol members, `SpaceSeparator`), and append kept runes to a `StringBuilder`. .NET exposes no Default_Ignorable_Code_Point property, so carry the set from Unicode's `DerivedCoreProperties.txt` as a sorted range table (or use ICU through `icu.net`); it MUST be checked before the category. `StenographerBilling` is `public const string SettingsKeyPrefix = "stenographer_billing_";`. Wire records are `public sealed record` types serialized with `System.Text.Json`, keeping the Swift names; nothing here touches `INotifyPropertyChanged`, `ObservableCollection` or the dispatcher.

<!-- No `## Reference Implementations` section is authored. Record the code that implements this
ingredient with `cookr implements <uuid|rdid> <location> --platform <p>` and `cookr confirm <uuid|rdid>`;
a compiled doc or skill shows those rows as a derived section here. -->

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/Wire/Sessions.swift` | confirmed (1.1.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/Wire/VisibleText.swift` | confirmed (1.1.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/Wire/StenographerBillingSettings.swift` | confirmed (1.1.0) |

## Design Decisions

**Decision**: The wire types live in a single caseless `Sessions` enum, extended by one file per route family, rather than as top-level types.
**Rationale**: The doc comment calls them "The session daemon's wire types" as one set; a namespace groups them under one qualified prefix, keeps short historical names such as `TurnAggregateDTO` from colliding with other toolkit types, and lets each family's file grow on its own. A caseless enum cannot be instantiated, so the namespace cannot be misused as a value.
**Approved**: pending

**Decision**: The moved types keep the names and fields they had in `StenographerXPCProtocol`.
**Rationale**: The doc comment: they "keep their names and fields inside this namespace, so a payload encoded by the old daemon decodes here unchanged." Keeping the shapes means no translation layer is needed while the old daemon and the new one coexist; the cost is that historical naming is frozen into the new API.
**Approved**: pending

**Decision**: The namespace sits in `AgenticDeveloperHubSDKCore` and imports only Foundation.
**Rationale**: The `Database` tier's daemon code (for example `AccountRouterQuotaSource.swift`, which extends `Sessions.AccountQuotaReadingDTO`, and `LegacySessionImporter`, which reads `Sessions.StenographerBilling.settingsKeyPrefix`) and the clients above it both reach the same types from Core, so dependencies point downward only.
**Approved**: pending

**Decision**: `VisibleText` is an allowlist of general categories, with default-ignorable code points refused first, rather than a denylist of known-bad characters.
**Rationale**: The doc comment: "An allowlist, so a code point nobody thought of is refused by default." The account router's tests show why: zero-width spaces, fillers such as U+3164, variation selectors, combining marks and private-use code points could each split a secret token or hide its prefix from `AccountRouterLog.scrub` if any survived. The cost is that legitimate emoji sequences and decomposed accents are flattened (see Edge Cases).
**Approved**: pending

**Decision**: Template names use the looser `ModelRouterTemplateValidation.isRefusedInName` denylist, not `VisibleText`.
**Rationale**: The `VisibleText` doc comment points to it, and that function's doc comment explains it: a denylist "so emoji (variation selectors, ZWJ sequences) and accents typed as combining marks stay allowed". A name the user types is shown back to that user, while `VisibleText` guards text from clients and upstreams on its way to terminals, logs and stored rows.
**Approved**: pending

**Decision**: Stenographer's billing settings key prefix is a constant in Core, while the key names and billing logic stay in the billing DTOs.
**Rationale**: The doc comment: it is "the one value both of its processes must agree on". Putting it in the lowest tier lets Stenographer's app and daemon, and the legacy importer that reads old Stenographer databases, share one spelling; `BillingSettingsKeys` notes that "a typo on either side is a knob that silently stops working".
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | Access Patterns |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | partial | Reliability |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | Security |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | partial | Internationalization |

separation-of-concerns passes: `Sessions.swift` declares only the namespace, `VisibleText.swift` only the scalar classification and filter, and `StenographerBillingSettings.swift` only the prefix; every wire type lives in a sibling file by route family, redaction stays in `AccountRouterLog`, and the billing keys and logic stay in `BillingDTOs.swift`. unit-test-coverage is partial: `VisibleText` is exercised only indirectly, through `AccountRouterRecordTests` driving `insertRouterExchange` and `AccountRouterLog.scrub`, with no test of `isVisible` per category; the prefix is pinned only through `LegacySessionImporterTests` fixtures that spell `stenographer_billing_` literally; and no test decodes a payload captured from the old Stenographer daemon to pin the namespace's backward-compatibility promise. api-design-conventions passes: every wire type is reached through one `Sessions.` prefix, the record types carry the `DTO` suffix inherited from the old protocol, and the helpers are caseless enums of static members. graceful-degradation is partial: the namespace promises that old payloads decode unchanged, which lets old and new daemons coexist, but whether each member type tolerates a missing or extra field is decided by that type's decoder. input-sanitization passes: `visible` reduces untrusted model ids, provider names and stop reasons to an allowlist of scalars before they are stored, removing terminal escapes (U+001B), bidi overrides and zero-width characters. secure-log-output passes: `VisibleText.isVisible` is the first step of `AccountRouterLog.scrub`, and deleting every control, line separator and invisible scalar before redaction keeps a log line to one line and leaves no invisible scalar inside a token for the redaction to miss. unicode-support is partial: letters, digits and symbols in every script are kept, but the filter does not normalize, so decomposed accents lose their marks, and joiners, variation selectors and enclosing keycaps are deleted, so emoji sequences break into their parts.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.0 | 2026-11-21 | Mike Fullerton | Cover VisibleText's scalar allowlist and StenographerBilling's settings key prefix alongside the Sessions namespace |

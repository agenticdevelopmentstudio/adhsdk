---
id: dfdb871e-bca1-45a7-a64d-9ab6af0c0917
title: "Model Router DTOs"
type: ingredient
version: 1.1.0
status: review
language: en
created: 2026-11-21
modified: 2026-11-21
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Model router wire types and request templates: tier targets, request kinds, template formats 1-3, validation, version-based selection, status and usage rows."
platforms:
  - swift
  - macos
tags:
  - foundation
  - sessions
  - model-router
  - wire
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Model Router DTOs

## Overview

Two files in `Core/Sessions/Wire` hold the value types the model router's daemon and its clients exchange, all nested in the `Sessions` namespace. The model router sends a Claude Code request down a template's ranked list of tiers to a smaller Claude model or to an LLM Provider configuration; these types are the vocabulary of that exchange and the pure logic over templates, not the routing itself.

`ModelRouterDTOs.swift` defines:

- `ModelThreadKind`: which kind of Claude Code conversation a request belongs to (`main`, `subagent`, `side`, `other`).
- `ModelFamily`: the model family a Claude model id names (`haiku`, `sonnet`, `opus`, `other`), with its routable ranking (`routable`, `size`) and a display title (`modelTitle`).
- `ModelTierDTO`: one tier a template defines (`id`, `name`).
- `ModelTierTarget`: what serves a tier, with a text form `claude:<haiku|sonnet|opus>` or `provider:<uuid>[/<model>]`, a failable parser and a printer.
- `ModelRouteConditionsDTO`: the conditions a request definition matches on (`thread`, `commands`, `system`, `message`).
- `ModelRequestKindDTO`: one kind of request a template recognizes (`id`, `name`, `when`), the reserved `unclassified` id, and the id rule `isValidId`.
- `LossyDecoded`: an internal wrapper that decodes one array element or yields nil, so one bad element is dropped instead of the whole array.
- `ModelRouterPreferencesDTO`: a partial write of the router's settings.
- `ModelRouterProviderDTO`: one configured AI provider a `provider:` target can name, without secrets.
- `ModelRouterStatusDTO`: the router's status as the daemon reports it.
- `ModelUsageRowDTO`: one usage-report line per (requested model, served model, provider).

`ModelRouterTemplates.swift` defines:

- `ClaudeCodeVersion`: a parsed, comparable Claude Code version (1 to 4 dot-separated whole numbers), with extraction from a `claude-cli/<version>` user agent.
- `ModelRouterTemplateDecodeError`: why a template file was refused, each with a one-sentence `reason`.
- `ModelRouterTemplateDTO`: one request template in four parts (tiers, requests, request-to-tier map, tier-to-target map) covering a range of Claude Code versions; its decoder reads formats 1, 2 and 3; readers over the four parts; the file codec `decodeFile` / `encodedFile`; and the defaults, including the built-in catalog of 44 request kinds and the one built-in template.
- `ModelRouterTemplateValidation`: the user-facing refusal sentences, the name-scalar denylist `isRefusedInName`, and `problem(_:others:)`, which returns the first problem with a template or nil.
- `ModelRouterTemplateSelector`: picks the template for a Claude Code version (`select`) and tells whether two templates' version ranges overlap (`overlaps`).

Everything here is a plain value or a pure function: no I/O, no logging, no shared mutable state. Reading and writing template files on disk and applying a preferences write is `ModelRouterTemplateStore` in the Database tier (it calls `decodeFile`, `encodedFile`, `problem`, `overlaps` and the `badId`, `builtInReadOnly` and `noSuchTemplate` sentences); building a status is `AccountRouterServer.modelStatus`; matching conditions against a live request is the routing policy (`ModelRoutingPolicy`, `ModelRequestFacts`).

## Behavioral Requirements

### Thread kind

- **thread-kind-cases**: `ModelThreadKind` MUST have exactly four cases whose raw strings are `main`, `subagent`, `side` and `other`.
- **thread-kind-codable**: `ModelThreadKind` MUST encode and decode as its raw string.
- **thread-kind-unknown-string**: Decoding a `ModelThreadKind` from any string other than the four raw values MUST fail; the type has no fallback case for unknown strings.

### Model family

- **family-cases**: `ModelFamily` MUST have exactly four cases whose raw strings are `haiku`, `sonnet`, `opus` and `other`.
- **family-routable-order**: `ModelFamily.routable` MUST be `[haiku, sonnet, opus]`, smallest first.
- **family-size**: `size` MUST return the family's index in `routable`: `0` for `haiku`, `1` for `sonnet`, `2` for `opus`.
- **family-other-unrouted**: `size` MUST return nil for `other`, marking a model that is never routed.
- **family-model-title**: `modelTitle` MUST return `Claude Haiku 5.5` for `haiku`, `Claude Sonnet 5.5` for `sonnet`, `Claude Opus 5.5` for `opus` and `Claude` for `other`.

### Tier

- **tier-fields**: `ModelTierDTO` MUST carry a string `id` and a string `name`, both mutable, and MUST be identified by `id`.
- **tier-order-is-ranking**: A template's tier list MUST be read smallest first; the doc comment declares that order to be the ranking routing compares by, and that a request is only ever sent down it, never up. `ModelTierDTO` itself carries no rank; the order is the template's.

### Tier target

- **target-cases**: `ModelTierTarget` MUST be either `claude(ModelFamily)` or `provider(UUID, model: String?)`.
- **target-not-codable**: `ModelTierTarget` MUST NOT be `Codable` itself; it travels as its `text` string and is read back with the failable string initializer.
- **target-claude-parse**: Parsing text that starts with `claude:` MUST yield `claude(family)` when the remainder is exactly the raw string of a family whose `size` is non-nil (`haiku`, `sonnet`, `opus`).
- **target-claude-other-refused**: Parsing `claude:other` MUST yield nil, because `other` has no `size`.
- **target-claude-case-sensitive**: Parsing MUST compare the family name case-sensitively, so `claude:Haiku` yields nil.
- **target-unknown-prefix**: Parsing text that starts with neither `claude:` nor `provider:` MUST yield nil.
- **target-provider-uuid**: For text starting with `provider:`, the characters up to the first `/` (or the end) MUST parse as a UUID, or the result MUST be nil.
- **target-provider-no-model**: `provider:<uuid>` with no `/` MUST yield `provider(uuid, model: nil)`.
- **target-provider-model**: `provider:<uuid>/<model>` MUST yield `provider(uuid, model: <model>)`, where `<model>` is everything after the first `/`.
- **target-model-slashes**: Only the first `/` MUST separate the UUID from the model; later slashes MUST stay in the model id (`org/model`).
- **target-model-empty-refused**: `provider:<uuid>/` (a slash followed by nothing) MUST yield nil.
- **target-model-refused-scalars**: A model id containing any scalar that `ModelRouterTemplateValidation.isRefusedInName` refuses MUST yield nil.
- **target-model-length**: A model id longer than 200 characters MUST yield nil; the count is in characters (extended grapheme clusters), not scalars or bytes.
- **target-claude-text**: `text` for `claude(family)` MUST be `claude:` followed by the family's raw string.
- **target-provider-text**: `text` for `provider(id, model)` MUST be `provider:` followed by the UUID in uppercase hyphenated form, followed by `/<model>` only when `model` is non-nil.
- **target-provider-id**: `providerId` MUST return the UUID for a `provider` target.
- **target-provider-id-claude**: `providerId` MUST return nil for a `claude` target.
- **target-hashable**: `ModelTierTarget` MUST be `Hashable` by its case and associated values.

### Route conditions

- **conditions-fields**: `ModelRouteConditionsDTO` MUST carry four optional fields: `thread` (`ModelThreadKind`), `commands` (`Bool`, the request's tools include Bash), `system` (`String`, text the system prompt contains, case-sensitive) and `message` (`String`, text the latest user message contains, case-sensitive).
- **conditions-defaults**: Every initializer parameter of `ModelRouteConditionsDTO` MUST default to nil, so `ModelRouteConditionsDTO()` sets no condition.
- **conditions-declared-semantics**: The doc comment declares that every condition that is set must hold for a request definition to match and that unset ones are ignored. This type only carries the values; the matching is owned by the routing policy (`ModelRoutingPolicy`, `ModelRequestFacts`).
- **conditions-retired-keys-ignored**: Decoding MUST ignore the retired `writes` and `max_tokens` keys (and any other unknown key) and MUST NOT fail because they are present.
- **conditions-nil-omitted**: Encoding MUST omit every nil field rather than writing a null.

### Request kind

- **request-kind-fields**: `ModelRequestKindDTO` MUST carry a string `id`, a string `name` and a required `when` (`ModelRouteConditionsDTO`), and MUST be identified by `id`.
- **request-kind-tier-not-carried**: Decoding MUST ignore a format-2 `tier` key and the retired `about` key; which tier a request goes to is the template's `request_tiers`, not the request's.
- **request-kind-unclassified-constants**: `unclassifiedId` MUST be `unclassified` and `unclassifiedName` MUST be `Unclassified`.
- **request-id-pattern**: `isValidId(id)` MUST return true only for an id matching the whole-string pattern `^[a-z0-9][a-z0-9-]{0,63}$`: a lowercase ASCII letter or digit first, then up to 63 lowercase ASCII letters, digits or dashes (1 to 64 characters in all).
- **request-id-unclassified-default**: `isValidId("unclassified")` MUST return false when `allowUnclassified` is omitted or false.
- **request-id-unclassified-allowed**: `isValidId("unclassified", allowUnclassified: true)` MUST return true.

### Lossy element decoding

- **lossy-element-drop**: `LossyDecoded<Value>` MUST hold the decoded value when the element decodes and nil when it does not, and MUST NOT throw, so a decoder of `[LossyDecoded<Value>]` drops a bad element instead of failing the whole array.
- **lossy-key-strategy**: `LossyDecoded` MUST decode the element with the surrounding decoder, so the decoder's key strategy (for example a snake-case conversion) applies to the element.
- **lossy-internal**: `LossyDecoded` MUST NOT be public API; it is module-internal and used by the format-2 template decoding.

### Preferences (partial write)

- **prefs-fields**: `ModelRouterPreferencesDTO` MUST carry five optional fields: `enabled` (`Bool`), `saveTemplate` (`ModelRouterTemplateDTO`), `deleteTemplate`, `preferTemplate` and `unpreferTemplate` (each a template id `String`).
- **prefs-nil-untouched**: A nil field MUST mean "leave the stored value unchanged", so a caller sends only what it means to change and never reads and writes back a value another writer may have changed.
- **prefs-defaults**: Every initializer parameter of `ModelRouterPreferencesDTO` MUST default to nil.
- **prefs-decode-sparse**: Decoding `{"enabled":true}` MUST succeed with `enabled == true` and every other field nil.
- **prefs-built-in-refused-elsewhere**: The type MUST NOT itself refuse any value; the doc comment states the daemon refuses a `saveTemplate` that reuses a built-in template's id, and that refusal is owned by `ModelRouterTemplateStore.plan`.

### Provider

- **provider-fields**: `ModelRouterProviderDTO` MUST carry `id` (`String`), `name` (`String`), `model` (`String`, the configuration's own model, used by a target that names none), `usable` (`Bool`, the daemon can build a route for it now) and `models` (`[String]?`, every model the provider's catalog lists for the configuration).
- **provider-immutable**: Every `ModelRouterProviderDTO` field MUST be read-only after construction.
- **provider-models-optional**: `models` MUST be optional and default to nil, so a payload from a daemon that sends none decodes.
- **provider-secret-free**: `ModelRouterProviderDTO` MUST NOT carry an API key or a URL.

### Status

- **status-required-fields**: `ModelRouterStatusDTO` MUST require `enabled` (`Bool`) and `providers` (`[ModelRouterProviderDTO]`).
- **status-optional-fields**: `ModelRouterStatusDTO` MUST treat `templates`, `preferred` (preferred template ids), `skipped` (skipped template files, each `"<file>: <reason>"`), `clientVersion`, `inUse` (id of the template last used for a request) and `inUseIsFallback` as optional, each defaulting to nil.
- **status-decode-sparse**: Decoding `{"enabled":true,"providers":[]}` MUST succeed with `templates` nil.
- **status-immutable**: Every `ModelRouterStatusDTO` field MUST be read-only after construction.

### Usage row

- **usage-fields**: `ModelUsageRowDTO` MUST carry optional `requestedModel`, `servedModel` and `provider` strings, and required integer `requests`, `inputTokens`, `outputTokens`, `cacheReadTokens` and `cacheCreationTokens`.
- **usage-anthropic-provider**: `provider` MUST be nil when Anthropic served the request, and otherwise the provider configuration's name.
- **usage-immutable**: Every `ModelUsageRowDTO` field MUST be read-only after construction.

### Claude Code version

- **version-parts-count**: `ClaudeCodeVersion(text)` MUST split on `.` keeping empty pieces and MUST yield nil unless there are 1 to 4 pieces.
- **version-piece-digits**: Each piece MUST be non-empty, ASCII-only, all numeric and representable as an `Int`, or the result MUST be nil; signs, spaces, letters and non-ASCII digits are refused.
- **version-description**: `description` MUST be the original text unchanged (`"02.1"` keeps its leading zero).
- **version-compare-numeric**: Ordering MUST compare the parts numerically and lexicographically after padding to 4 parts with zeros, so `2.1.99 < 2.1.296`.
- **version-equality-padded**: Equality and hashing MUST use the zero-padded parts, so `2.1 == 2.1.0` and both hash alike.
- **version-from-user-agent**: `fromUserAgent` MUST take the text after the first `claude-cli/` up to the first space or `(` and parse it as a version.
- **version-from-user-agent-nil**: `fromUserAgent` MUST return nil for a nil user agent, one without `claude-cli/`, or one whose token does not parse.

### Template decode errors

- **decode-error-cases**: `ModelRouterTemplateDecodeError` MUST have exactly the cases `unreadable`, `newerFormat(Int)`, `unreadableRequests(Int)` and `unreadableSection(String)`, and MUST be `Equatable`.
- **decode-error-reasons**: `reason` MUST return `not a template file`, `made for a newer Stenographer (format N)`, `N of its request definitions can't be read, so the file was not imported` and `its S can't be read, so the file was not imported` for the four cases respectively.

### Template shape

- **template-fields**: `ModelRouterTemplateDTO` MUST carry `format` (`Int`), `id`, `name`, `claudeCode` (`VersionRange` of `from` and `through` strings), `tiers` (`[ModelTierDTO]`), `requests` (`[ModelRequestKindDTO]`), `requestTiers` (request id to tier id) and `tierTargets` (tier id to target text), all mutable, and MUST be identified by `id`.
- **template-version-range**: `VersionRange` MUST carry two mutable strings, `from` and `through`, with synthesized `Codable` using those property names as keys and synthesized equality; the strings are not parsed until validation or selection.
- **template-current-format**: `currentFormat` MUST be `3`.
- **template-init-defaults**: The memberwise initializer MUST default `format` to `3`, `tiers` to `defaultTiers`, `tierTargets` to `defaultTierTargets`, and a nil `requestTiers` to `defaultRequestTiers(for: requests)`.
- **template-is-built-in**: `isBuiltIn` MUST be true exactly when `id` starts with `builtin.`.
- **template-version-text**: `versionText` MUST be `from` alone when `from` and `through` are equal strings, and otherwise `from – through` with an en dash between single spaces.

### Template decoding (stored data)

- **decode-required-keys**: Decoding MUST require `format` (an integer), `id` and `name`, and MUST throw when any is missing.
- **decode-claude-code-spellings**: Decoding MUST read the version range from `claude_code`, or from `claudeCode` when `claude_code` is absent, and MUST throw when neither is present.
- **decode-format-upgraded**: The decoded `format` MUST be the larger of the stored format and `3`, so formats 1 and 2 come back as `3` and a stored `4` stays `4`.
- **decode-format-1**: A stored format below 2 MUST keep its `id`, `name` and range and MUST take `defaultTiers`, `builtInRequests`, `defaultRequestTiers(for: builtInRequests)` and `defaultTierTargets`, ignoring any other key in the data.
- **decode-format-2-requests**: A stored format 2 MUST decode `requests` element by element, dropping each element that does not decode and keeping the rest in order.
- **decode-format-2-requests-not-array**: A stored format 2 whose `requests` is absent or not an array MUST decode with no requests rather than throw.
- **decode-format-2-tier-key**: A format-2 request element whose `tier` is present but is not `light`, `standard` or `heavy` MUST be dropped.
- **decode-format-2-request-tiers**: A stored format 2 MUST build `requestTiers` from each kept request's `tier`, or from `defaultTierId(forRequest:)` when the element has none.
- **decode-format-2-unclassified**: A stored format 2 MUST map `unclassified` to `unclassified_tier`, else `unclassifiedTier`, else `heavy`.
- **decode-format-2-unclassified-bad**: A stored format 2 whose unclassified tier is not `light`, `standard` or `heavy` MUST throw.
- **decode-format-2-defaults**: A stored format 2 MUST take `defaultTiers` and `defaultTierTargets`.
- **decode-format-3-sections**: A stored format of 3 or more MUST read each of `tiers`, `requests`, `request_tiers` (or `requestTiers`) and `tier_targets` (or `tierTargets`); the snake-case key MUST win when both spellings are present.
- **decode-format-3-missing-default**: A format-3 section that is absent MUST take its default: `defaultTiers`, `builtInRequests`, `defaultRequestTiers(for:)` of the decoded requests, and `defaultTierTargets`.
- **decode-format-3-bad-section**: A format-3 section that is present but does not decode MUST throw `unreadableSection` with the title `tiers`, `requests`, `request tiers` or `tier models`; one bad request element fails the whole `requests` section.

### Template encoding and files

- **encode-keys**: Encoding MUST write `format`, `id`, `name`, `claude_code`, `tiers`, `requests`, `request_tiers` and `tier_targets`, and MUST NOT write `unclassified_tier` or any retired key.
- **encoded-file-format**: `encodedFile()` MUST produce pretty-printed JSON with sorted keys.
- **encoded-file-failure**: `encodedFile()` MUST return empty data, with no error, if encoding throws.
- **decode-file-not-object**: `decodeFile` MUST return `unreadable` when the data is not a JSON object.
- **decode-file-newer**: `decodeFile` MUST return `newerFormat(n)` when the object's integer `format` is greater than `3`, before attempting a decode.
- **decode-file-section-error**: `decodeFile` MUST return a `ModelRouterTemplateDecodeError` thrown by the decoder unchanged.
- **decode-file-other-error**: `decodeFile` MUST return `unreadable` for any other decode failure.
- **decode-file-format-2-requests-type**: For a format-2 object whose `requests` key is present but not an array, `decodeFile` MUST return `unreadable`.
- **decode-file-format-2-all-or-nothing**: For a format-2 object, `decodeFile` MUST return `unreadableRequests(k)` when `k` listed request elements were dropped, `k` being the listed count minus the decoded count.
- **decode-file-round-trip**: `decodeFile(t.encodedFile())` MUST succeed with a template equal to `t` for any format-3 template `t`.

### Template readers

- **reader-tier-for-request**: `tierId(forRequest:)` MUST return the request's own `requestTiers` entry, else the `unclassified` entry, else nil.
- **reader-tier**: `tier(_:)` MUST return the first tier with that id, or nil.
- **reader-rank**: `rank(ofTier:)` MUST return the tier's 0-based index in `tiers`, or nil.
- **reader-target**: `target(forTier:)` MUST return the parsed `ModelTierTarget` of the tier's entry, or nil when the entry is missing or does not parse.
- **reader-names-mapped**: `names(mappedTo:)` MUST return, in `requests` order, the names of the requests whose own `requestTiers` entry equals the tier id, followed by `Unclassified` when the `unclassified` entry equals it; a request with no entry of its own is not listed.
- **reader-removal-none**: `removalProblem(tierId:)` MUST return nil when `names(mappedTo:)` is empty.
- **reader-removal-sentence**: Otherwise it MUST return `<list> still go to <tier name>. Choose another tier for them first.`, using `goes` and `it` when exactly one name is listed, the tier's name (or its id when no tier has that id), and the names joined by the current locale's list formatter.

### Defaults and built-ins

- **default-tiers**: `defaultTiers` MUST be `light` (`Light`), `standard` (`Standard`) and `heavy` (`Heavy`), in that order.
- **default-tier-targets**: `defaultTierTargets` MUST map `light` to `claude:haiku`, `standard` to `claude:sonnet` and `heavy` to `claude:opus`.
- **default-tier-for-request**: `defaultTierId(forRequest:)` MUST return the catalog tier of a request id in `builtInCatalog`, and `heavy` for any other id, `unclassified` included.
- **default-request-tiers**: `defaultRequestTiers(for:)` MUST map `unclassified` and every given request id to its default tier.
- **built-in-catalog**: `builtInCatalog` MUST hold 44 request kinds in a fixed order, beginning with `explore-subagent` and ending with the three fallbacks `background` (thread `side`, light), `search-subagent` (thread `subagent`, `commands` false, light) and `command-subagent` (thread `subagent`, `commands` true, standard).
- **built-in-catalog-text**: Every catalog entry except the three fallbacks MUST be recognized by a `system` or `message` text and a thread kind.
- **built-in-requests**: `builtInRequests` MUST be the catalog's requests in catalog order.
- **built-in-template**: `builtIns` MUST hold exactly one template: id `builtin.claude-code.2.1.296`, name `Claude Code 2.1.296`, range `2.1.296` through `2.1.296`, format 3, default tiers, built-in requests, default request tiers and default tier targets.
- **built-in-version-range**: The built-in template's range MUST stay `2.1.296` through `2.1.296` even though the `builtInCatalog` doc comment says its requests are those "Claude Code 2.1.302 sends"; a 2.1.302 client therefore gets the built-in only as a fallback (`isFallback` true) unless another template covers that version.
- **built-in-valid**: The built-in template MUST pass `ModelRouterTemplateValidation.problem` with no others.

### Template validation

- **refused-scalars**: `isRefusedInName` MUST return true for general categories Cc (control), Zl (line separator) and Zp (paragraph separator) and for U+200E, U+200F, U+202A–U+202E and U+2066–U+2069, and false for every other scalar, so emoji, ZWJ sequences, variation selectors, combining marks and U+200B stay allowed.
- **problem-order**: `problem(_:others:)` MUST return the first problem found in this order: name, version range, tiers, requests, request and tier mapping; and nil when there is none.
- **problem-name-missing**: A name that is empty after trimming whitespace and newlines MUST return `nameMissing`.
- **problem-name-controls**: A name holding a refused scalar MUST return `nameHasControls`.
- **problem-name-length**: A name longer than 80 characters, counted untrimmed in grapheme clusters, MUST return `nameTooLong`.
- **problem-name-taken**: A name whose trimmed form equals, case-insensitively, the trimmed name of an entry in `others` with a different id MUST return `nameTaken`; an entry with the same id is the template itself and MUST NOT clash.
- **problem-version**: A `from` or `through` that does not parse as a `ClaudeCodeVersion` MUST return `badVersion`.
- **problem-backwards**: `through` lower than `from` MUST return `backwardsRange`.
- **problem-tiers**: An empty tier list MUST return `noTiers`; a tier id failing `isValidId` (which refuses `unclassified`) MUST return `badTierId`; a repeated tier id MUST return `duplicateTierId`; a trimmed-empty tier name MUST return `tierNameMissing`; a tier name with a refused scalar or over 80 characters MUST return `tierNameBad`; and two tier names equal after trimming and lowercasing MUST return `tierNameTaken`.
- **problem-requests**: A request id failing `isValidId` MUST return `badRequestId`; a repeated request id MUST return `duplicateRequestId`; a trimmed-empty request name MUST return `requestNameMissing`; a request name with a refused scalar or over 80 characters MUST return `requestNameBad`; and two request names equal after trimming and lowercasing MUST return `requestNameTaken`.
- **problem-match-text**: A request whose `system` or `message` text exceeds 400 characters or holds a refused scalar MUST return `matchTextBad`; an empty match text is accepted.
- **problem-empty-requests**: A template with no requests MUST be valid when its only `requestTiers` entry is `unclassified`.
- **problem-request-tier-missing**: A request id, or `unclassified`, with no `requestTiers` entry MUST return `requestTierMissing`.
- **problem-request-tier-unknown**: A `requestTiers` value that names no tier of the template MUST return `requestTierUnknown`.
- **problem-request-tier-stray**: A `requestTiers` key that is neither a request id nor `unclassified` MUST return `requestTierStray`.
- **problem-tier-target-missing**: A tier with no `tierTargets` entry MUST return `tierTargetMissing`.
- **problem-tier-target-bad**: A `tierTargets` value that does not parse as a `ModelTierTarget` MUST return `tierTargetBad`.
- **problem-tier-target-stray**: A `tierTargets` key that names no tier MUST return `tierTargetStray`.
- **problem-unknown-provider**: A well-formed `provider:<uuid>` target MUST be accepted whether or not a provider with that id exists.
- **problem-sentences**: Each refusal MUST be the exact English sentence of its constant in `ModelRouterTemplateValidation`, as listed under Localization.

### Template selection

- **select-covered**: When `version` is non-nil, `select` MUST pick, among templates whose parsed range satisfies `from <= version <= through`, the first by the selection order, with `isFallback` false.
- **select-order**: The selection order MUST put preferred ids first, then built-in templates, then names in case-insensitive ascending order, then ids in ascending order.
- **select-fallback**: When no template covers the version, or `version` is nil, `select` MUST pick, among templates whose range parses, those whose `through` is the latest, and the first of them by the selection order, with `isFallback` true.
- **select-fallback-ignores-nearness**: The fallback MUST be the latest-reaching template even when the version lies below or between ranges.
- **select-none**: `select` MUST return nil when no template has a parseable range.
- **select-unparseable-skipped**: A template whose `from` or `through` does not parse MUST never be selected.
- **overlaps-inclusive**: `overlaps` MUST return true exactly when both ranges parse and `lhs.from <= rhs.through` and `rhs.from <= lhs.through`, and false when either range does not parse.

### Shared contract

- **sendable**: Every public data type in both files (every struct, the case-bearing enums, `ModelTierTarget`, `ClaudeCodeVersion`, `VersionRange`, `Selection` and `DefaultTier`) MUST be `Sendable`, so any value can cross threads or actors. The caseless namespaces `ModelRouterTemplateValidation` and `ModelRouterTemplateSelector` declare no conformance; they hold only `static let` constants and pure static functions.
- **equatable**: Every public struct MUST be `Equatable` by all of its stored fields; `ClaudeCodeVersion` is the exception, equal by its padded parts.
- **coding-keys-dtos**: Every `Codable` struct other than `ModelRouterTemplateDTO` MUST use its property names as coding keys; the wire spelling is chosen by the caller's key strategy.
- **no-side-effects**: The types in both files MUST NOT perform I/O, logging or any other side effect; parsing, printing, validation and selection are pure.

## Appearance

Not applicable — this is a set of wire data types and pure template logic, not a visual component.

## States

Not applicable — this is a set of wire data types and pure template logic, not a visual component.

## Accessibility

Not applicable — this is a set of wire data types and pure template logic, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mrdto-001 | request-id-pattern | `isValidId("a-1")` (`ModelRouterSettingsTests.testIdRules`) | `true` |
| mrdto-002 | request-id-unclassified-default | `isValidId("unclassified")` (`testIdRules`) | `false` |
| mrdto-003 | request-id-unclassified-allowed | `isValidId("unclassified", allowUnclassified: true)` (`testIdRules`) | `true` |
| mrdto-004 | request-id-pattern | `isValidId` of each of `""`, `"-a"`, `"A"`, `"a_b"`, `"a b"`, and 65 `a`s (`testIdRules`) | `false` for every one |
| mrdto-005 | request-id-pattern | `isValidId` of 64 `a`s (`testIdRules`) | `true` |
| mrdto-006 | conditions-retired-keys-ignored, request-kind-tier-not-carried | Decode `{"id":"x","name":"X","tier":"light","when":{"thread":"subagent","writes":true,"commands":false,"max_tokens":500,"maxTokens":500}}` as `ModelRequestKindDTO` (`ModelRouterTemplatesTests.testRetiredWritesAndMaxTokensKeysDecodeAndAreIgnored`) | Succeeds; `when == ModelRouteConditionsDTO(thread: .subagent, commands: false)` |
| mrdto-007 | prefs-decode-sparse | Decode `{"enabled":true}` as `ModelRouterPreferencesDTO` (`testPreferencesAndStatusDecodeWithoutTheNewFields`) | Succeeds; `saveTemplate == nil`, `preferTemplate == nil` |
| mrdto-008 | status-decode-sparse, status-required-fields | Decode `{"enabled":true,"providers":[]}` as `ModelRouterStatusDTO` (`testPreferencesAndStatusDecodeWithoutTheNewFields`) | Succeeds; `templates == nil` |
| mrdto-009 | target-unknown-prefix, problem-tier-target-bad | A template whose `tierTargets["light"]` is `"gpt"` (`testTierAndMappingValidationSentences`) | `problem` returns `tierTargetBad` |
| mrdto-010 | target-provider-no-model, problem-unknown-provider | A template whose `tierTargets["light"]` is `"provider:" + <fresh UUID string>` (`testTierAndMappingValidationSentences`) | `problem` returns nil |
| mrdto-011 | target-provider-text, target-provider-model, decode-file-round-trip | Add tier `huge` with target `ModelTierTarget.provider(id, model: "big-1").text`, encode the file, decode it (`testTheFourPartsRoundTripAndBothKeySpellingsRead`) | Decoded template equals the original; target text is `"provider:" + id.uuidString + "/big-1"` |
| mrdto-012 | target-claude-parse, target-claude-text | `ModelTierTarget("claude:haiku")`; `.claude(.opus).text` | `claude(.haiku)`; `"claude:opus"` |
| mrdto-013 | target-claude-other-refused | `ModelTierTarget("claude:other")` | nil |
| mrdto-014 | target-claude-case-sensitive | `ModelTierTarget("claude:Haiku")` | nil |
| mrdto-015 | target-model-slashes | `ModelTierTarget("provider:<uuid>/org/model")` | `provider(uuid, model: "org/model")` |
| mrdto-016 | target-model-empty-refused | `ModelTierTarget("provider:<uuid>/")` | nil |
| mrdto-017 | target-provider-uuid | `ModelTierTarget("provider:not-a-uuid/m")`; `ModelTierTarget("provider:")` | nil; nil |
| mrdto-018 | target-model-refused-scalars | `ModelTierTarget("provider:<uuid>/a\nb")`; `ModelTierTarget("provider:<uuid>/x\u{202E}")` | nil; nil |
| mrdto-019 | target-model-length | Model id of 200 characters; model id of 201 characters | `provider(uuid, model: <200 chars>)`; nil |
| mrdto-020 | target-provider-text | `ModelTierTarget("provider:<lowercase uuid>").text` | `"provider:" + <same uuid uppercased>` |
| mrdto-021 | target-provider-id, target-provider-id-claude | `.provider(id, model: nil).providerId`; `.claude(.sonnet).providerId` | `id`; nil |
| mrdto-022 | family-size, family-other-unrouted, family-routable-order | `size` of `haiku`, `sonnet`, `opus`, `other`; `routable` | `0`, `1`, `2`, nil; `[haiku, sonnet, opus]` |
| mrdto-023 | family-model-title | `modelTitle` of each family | `Claude Haiku 5.5`, `Claude Sonnet 5.5`, `Claude Opus 5.5`, `Claude` |
| mrdto-024 | thread-kind-cases, thread-kind-codable, thread-kind-unknown-string | Decode `"subagent"`; decode `"background"` as `ModelThreadKind` | `.subagent`; decoding throws |
| mrdto-025 | lossy-element-drop, lossy-key-strategy | Decode `[LossyDecoded<ModelTierDTO>]` from `[{"id":"a","name":"A"},{"id":1}]` | Two elements; the first's value is `ModelTierDTO(id: "a", name: "A")`, the second's is nil; no error |
| mrdto-026 | conditions-nil-omitted, conditions-defaults | Encode `ModelRouteConditionsDTO()` | `{}` |
| mrdto-027 | provider-models-optional | Decode `{"id":"p","name":"P","model":"m","usable":true}` as `ModelRouterProviderDTO` | Succeeds; `models == nil` |
| mrdto-028 | usage-fields | Decode a `ModelUsageRowDTO` object missing `requests` | Decoding throws |
| mrdto-029 | version-parts-count, version-piece-digits, version-description | `ClaudeCodeVersion` of `"2.1.296"`, `""`, `"2.1.x"`, `"1.2.3.4.5"`, `" 2.1"` (`testVersionParsingAndOrdering`) | description `"2.1.296"`; nil; nil; nil; nil |
| mrdto-030 | version-compare-numeric, version-equality-padded | `2.1.99 < 2.1.296`; `2.1 == 2.1.0` (`testVersionParsingAndOrdering`) | both true |
| mrdto-031 | version-from-user-agent, version-from-user-agent-nil | `fromUserAgent` of `"claude-cli/2.1.296 (external, cli)"`, `"claude-cli/2.1.300(x)"`, `"curl/8.7.1"`, nil, `"claude-cli/beta"` (`testUserAgentExtraction`) | `"2.1.296"`; `"2.1.300"`; nil; nil; nil |
| mrdto-032 | built-in-template, built-in-catalog, built-in-catalog-text, template-is-built-in, template-version-text, built-in-valid | `builtIns.first` (`testBuiltInCarriesTheSpecsRequests`) | format 3, id `builtin.claude-code.2.1.296`, 44 requests, first `explore-subagent`, last three `background`, `search-subagent`, `command-subagent`; `isBuiltIn`; `versionText == "2.1.296"`; `problem` nil |
| mrdto-033 | default-tiers, default-tier-targets, default-tier-for-request, default-request-tiers, reader-tier-for-request, reader-rank | Built-in template (`testTheBuiltInCarriesItsTiersRequestTiersAndModels`) | tiers `light, standard, heavy`; `requestTiers["plan-subagent"] == "heavy"`, `["unclassified"] == "heavy"`; `tierTargets` haiku/sonnet/opus; `tierId(forRequest: "search-subagent") == "light"`; `rank(ofTier: "heavy") == 2`; `defaultTierId(forRequest: "anything-else") == "heavy"` |
| mrdto-034 | reader-names-mapped, reader-removal-sentence, reader-removal-none | `removalProblem(tierId: "heavy")` on the built-in; then with every heavy request moved to standard, in an English locale (`testATierInUseNamesWhatStillGoesToIt`) | `"Plan subagent, Agent team teammate, Worker fork subagent, Compaction, Auto mode permission classifier, Compaction (instruction), and Unclassified still go to Heavy. Choose another tier for them first."`; then `"Unclassified still goes to Heavy. Choose another tier for it first."` |
| mrdto-035 | decode-format-2-request-tiers, decode-format-2-unclassified, decode-format-upgraded, decode-format-2-defaults | `decodeFile` of a format-2 file with requests `background`, `search-subagent`, `command-subagent`, `editing-subagent`, `mine`, no tiers, no `unclassified_tier` (`testARequestWithoutATierTakesItsIdsDefault`) | format 3; `requestTiers` light, light, standard, heavy, heavy, and `unclassified` heavy; default tiers and targets; `problem` nil |
| mrdto-036 | decode-format-2-tier-key, decode-file-format-2-all-or-nothing, decode-format-2-unclassified-bad | Format-2 data with requests `x` (tier `huge`) and `y` (tier `light`): decode as stored data, then `decodeFile`; and a file with `"unclassified_tier":"huge"` (`testAnInvalidTierDropsTheStoredElementAndRefusesTheFile`) | stored: requests `["y"]`, `requestTiers == ["y": "light", "unclassified": "heavy"]`; file: `.failure(.unreadableRequests(1))`; bad unclassified: `.failure(.unreadable)` |
| mrdto-037 | decode-claude-code-spellings, decode-format-3-sections, encode-keys | Decode format 2 with `claudeCode` and `unclassifiedTier: "standard"`; decode format 3 with camel `requestTiers`, `tierTargets` (`testTheFourPartsRoundTripAndBothKeySpellingsRead`) | `requestTiers["unclassified"] == "standard"`; camel maps read; an encoded file contains `"request_tiers"`, `"tier_targets"` and no `unclassified_tier` |
| mrdto-038 | decode-format-3-missing-default, decode-format-3-bad-section, decode-error-reasons | `decodeFile` of a bare format-3 file; then with each of `tiers`, `requests`, `request_tiers`, `tier_targets` set to `7` (`testAFormatThreeFileTakesDefaultsForMissingPartsAndNamesABadOne`) | defaults for all four parts; `.unreadableSection("tiers")`, `("requests")`, `("request tiers")`, `("tier models")`; reason `"its tiers can't be read, so the file was not imported"` |
| mrdto-039 | decode-file-not-object, decode-file-newer, decode-format-2-requests, decode-file-format-2-requests-type, decode-format-2-requests-not-array, template-version-text | `decodeFile("nope")`; a template with `format = 4`; format-2 requests `[{"id":"x","name":"X"},7,{"id":"y",...}]` stored and as a file; `"requests":7` as a file; no `requests` (`testFileRoundTripAndBadFiles`) | `.unreadable`; `.newerFormat(4)`; stored keeps only `y`, file `.unreadableRequests(2)`; `.unreadable`; requests `[]`; `versionText == "2.1.290 – 2.1.296"` |
| mrdto-040 | decode-format-1 | `decodeFile` of a format-1 file with `provider`, `model`, `rules`, `models` keys (`testAFormatOneFileConvertsWithTheBuiltInRequests`) | Equals `ModelRouterTemplateDTO(id: "old", name: "Old", claudeCode: 2.1.200–2.1.296, requests: builtInRequests)`; format 3 |
| mrdto-041 | problem-name-missing, problem-name-taken, problem-version, problem-backwards, problem-empty-requests, problem-request-tier-stray | Template `Mine`: name `"  "`; name = built-in name uppercased with the built-in in `others`; `from = "two"`; `2.1.300`–`2.1.296`; same id in `others`; `requests = []` (`testValidation`) | `nameMissing`; `nameTaken`; `badVersion`; `backwardsRange`; nil; non-nil until `requestTiers` is reset to `defaultRequestTiers(for: [])`, then nil |
| mrdto-042 | problem-requests | Request id `unclassified`, `Bad`, `""`, `-x`, `a_b`; duplicate id; name `" "`; name `" background TASK"`; name `"Tab\there"`; 81-char name; 80-char name (`testRequestValidationSentences`) | `badRequestId` ×5; `duplicateRequestId`; `requestNameMissing`; `requestNameTaken`; `requestNameBad`; `requestNameBad`; nil |
| mrdto-043 | problem-tiers, problem-request-tier-missing, problem-request-tier-unknown, problem-tier-target-missing, problem-tier-target-stray | `tiers = []`; tier id `Bad`; duplicate tier id; tier name `" "`; `LIGHT`; `Flip\u{202E}`; 81 chars; remove `background`'s or `unclassified`'s request tier; `background` to `huge`; `gone` to `light`; remove `light`'s target; target for `huge` (`testTierAndMappingValidationSentences`) | `noTiers`; `badTierId`; `duplicateTierId`; `tierNameMissing`; `tierNameTaken`; `tierNameBad` ×2; `requestTierMissing` ×2; `requestTierUnknown`; `requestTierStray`; `tierTargetMissing`; `tierTargetStray` |
| mrdto-044 | refused-scalars, problem-name-controls, problem-name-length | Names with ESC, tab, U+202E, BEL, U+2066, U+200F, U+2028, U+2029; 81 `n`s; 80 `n`s (`testNamesRefuseControlsBidiAndLineBreaksAndCapTheLength`) | `nameHasControls` ×8; `nameTooLong`; nil |
| mrdto-045 | refused-scalars | Names `"Cafe\u{301}"`, `"\u{2764}\u{FE0F} Opus"`, a ZWJ family emoji, `"Zero\u{200B}width"` (`testNamesAllowEmojiAndCombiningAccents`) | nil for every one |
| mrdto-046 | problem-name-length | 80 ZWJ family emoji; 81 `e` + U+0301 (`testTheNameCapCountsCharactersNotScalars`) | nil; `nameTooLong` |
| mrdto-047 | select-covered, select-order | `alpha` (2.1.290–2.1.300), `Beta` (2.1.296), `builtin.x`; version 2.1.296, no preference; preferred `B`; `[beta, alpha]` only; version 2.1.299 (`testSelectorCoveredPreferredAndTieBreaks`) | built-in, not fallback; `beta`; `alpha` (name order); `alpha` |
| mrdto-048 | select-fallback, select-fallback-ignores-nearness, select-none, overlaps-inclusive | `Old` (2.0.0–2.1.100), `New` (2.1.200–2.1.296); versions 2.1.310, nil, 2.1.150; `[]`; overlaps with a 2.1.100–2.1.100 template; `Old` vs `New` (`testSelectorFallsBackToTheLatest`) | `New`, fallback, in all three; nil; true; false |
| mrdto-049 | decode-error-cases, decode-error-reasons | `.unreadable.reason`; `.newerFormat(4).reason`; `.unreadableRequests(2).reason` (`testFileRoundTripAndBadFiles` for the last) | `"not a template file"`; `"made for a newer Stenographer (format 4)"`; `"2 of its request definitions can't be read, so the file was not imported"` |
| mrdto-050 | problem-match-text | A request with `system` of 401 characters; of 400 characters; with a tab | `matchTextBad`; nil; `matchTextBad` |
| mrdto-051 | select-unparseable-skipped | `select([t])` where `t.claudeCode.from == "x"`, any version | nil |
| mrdto-052 | reader-target, reader-tier | `target(forTier: "light")` on the built-in; after `tierTargets["light"] = "gpt"`; `tier("nope")` | `claude(.haiku)`; nil; nil |

Vectors mrdto-001 to mrdto-008 and mrdto-029 to mrdto-049 are asserted by tests in the SDK (`Tests/AgenticDeveloperHubSDKDatabaseTests/Daemon/AccountRouter/ModelRouterSettingsTests.swift` and `Tests/AgenticDeveloperHubSDKCoreTests/Sessions/ModelRouterTemplatesTests.swift`), except the `unreadable` and `newerFormat` reasons in mrdto-049. Vectors mrdto-009 to mrdto-011 cover `ModelTierTarget` indirectly, through template validation and file round-trips. The rest are derived from the source and have no dedicated test.

## Edge Cases

- **Empty tier-target text**: `ModelTierTarget("")` has neither prefix and MUST yield nil.
- **`claude:` with nothing after it**: The empty remainder is not a family raw value, so parsing MUST yield nil.
- **Provider text with no UUID**: `provider:` or `provider:/model` gives an empty UUID string, which MUST yield nil.
- **Provider text with trailing characters on the UUID**: `provider:<uuid>x` makes the UUID part `<uuid>x`, which does not parse, so the result MUST be nil.
- **Lowercase UUID**: A lowercase UUID MUST parse and MUST print back uppercase, so the round trip normalizes case rather than returning the original text.
- **Model at the length boundary**: exactly 200 characters MUST parse; 201 MUST yield nil. 200 emoji built from several scalars each still count 200.
- **Request id boundaries**: a 1-character id and a 64-character id MUST be valid; an empty id, a 65-character id, a leading dash, an uppercase letter, an underscore, a space or a non-ASCII letter MUST make the id invalid.
- **Retired keys in stored data**: `writes`, `max_tokens`, `tier`, `about`, format 1's `provider`, `model`, `rules` and `models`, and format 2's `unclassified_tier` MUST be ignored or converted on decode and MUST NOT reappear on encode.
- **Unknown thread string**: a `thread` value outside the four raw strings MUST fail the decode of the enclosing `ModelRouteConditionsDTO`; inside format-2 requests that drops only the one element, and inside format-3 requests it fails the `requests` section (`unreadableSection("requests")`).
- **Version text edge forms**: `"2."`, `".1"` and `"2..1"` have an empty piece and MUST yield nil; a piece too large for `Int` MUST yield nil; `"02.1"` MUST parse equal to `"2.1"` while keeping `"02.1"` as its description.
- **User agent with two markers**: only the first `claude-cli/` MUST be read.
- **Version text equal but spelled differently**: a range `2.1`–`2.1.0` MUST show `versionText` as `2.1 – 2.1.0`, because `versionText` compares strings, while selection treats the two ends as equal.
- **Format 0 or negative**: MUST decode through the format-1 branch and come back as format 3.
- **Stored format above 3 through the plain decoder**: MUST decode as format 3 does and keep its number; only `decodeFile` refuses it (`newerFormat`), so a re-encoded format-4 template is refused when read back as a file.
- **Missing `format`, `id`, `name` or range**: the plain decoder MUST throw; `decodeFile` MUST return `unreadable`.
- **Malformed `claude_code`**: a present but undecodable `claude_code` MUST throw a decoding error without trying `claudeCode`; `decodeFile` MUST return `unreadable`.
- **Format-2 duplicate request ids**: both requests MUST be kept and the later element's tier MUST win in `requestTiers`; validation then returns `duplicateRequestId`.
- **Format-3 request tiers absent but requests present**: `requestTiers` MUST default from the decoded requests, not from the built-in requests.
- **Non-JSON or array data**: `decodeFile` MUST return `unreadable`.
- **Encoding failure**: `encodedFile()` MUST return empty data; no member of the template is a floating-point value, so the synthesized encoder has no failing input in practice.
- **Removal of an unknown tier**: `removalProblem` MUST name the tier by its id when no tier has that id and something still maps to it.
- **Validation short-circuit**: `problem` MUST report only the first problem; a template with several problems needs several fixes and re-checks.
- **Name comparisons differ**: the template name clash MUST use case-insensitive comparison against `others`, while tier and request name clashes MUST compare `lowercased()` forms within the template.
- **No templates or no parseable range**: `select` MUST return nil.
- **Preferred template outside the version**: a preferred template MUST win only among templates that cover the version, or among those reaching the latest version in a fallback; a preferred but older template MUST NOT be selected over a later-reaching one in a fallback.
- **Concurrent access**: every type is a `Sendable` value type or a caseless namespace of pure static functions over immutable `static let` data, so concurrent calls MUST be safe without locking; mutating a `var` field affects only that copy.
- **Missing file, unreachable server, timeouts, cancellation**: not applicable; the files do no I/O and have no long-running operation. Reading template files and their failures belong to `ModelRouterTemplateStore`; transport belongs to the daemon client and server.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `allowUnclassified` (parameter of `ModelRequestKindDTO.isValidId`) | `Bool` | `false` | Whether the reserved id `unclassified` counts as valid. |
| `ModelRouteConditionsDTO.init` parameters | optional fields | all nil | Unset conditions are ignored. |
| `ModelRouterPreferencesDTO.init` parameters | optional fields | all nil | A nil field leaves the stored value untouched. |
| `ModelRouterProviderDTO.init` `models` | `[String]?` | nil | The provider's catalog of models, when the daemon sends one. |
| `ModelRouterStatusDTO.init` optional parameters | optional fields | all nil | `templates`, `preferred`, `skipped`, `clientVersion`, `inUse`, `inUseIsFallback`. |
| `ModelRouterTemplateDTO.init` `format` | `Int` | `3` | The template's format number. |
| `ModelRouterTemplateDTO.init` `tiers` | `[ModelTierDTO]` | `defaultTiers` | Light, Standard, Heavy. |
| `ModelRouterTemplateDTO.init` `requestTiers` | `[String: String]?` | `defaultRequestTiers(for: requests)` | Request id to tier id. |
| `ModelRouterTemplateDTO.init` `tierTargets` | `[String: String]` | `defaultTierTargets` | Tier id to target text. |
| `select` `preferred` | `Set<String>` | none (required) | Template ids the user prefers; first in the selection order. |
| `select` `version` | `ClaudeCodeVersion?` | none (required) | The client's version; nil selects the latest-reaching template as a fallback. |
| `problem` `others` | `[ModelRouterTemplateDTO]` | none (required) | Templates whose names a new name must not repeat. |
| Encoder / decoder key strategy | caller-supplied | property names | The wire spelling of every DTO key; the template accepts both snake and converted camel keys and always writes snake keys. |
| Model id length cap (`ModelTierTarget`) | constant | 200 characters | Longest model id a `provider:` target accepts. |
| `maxNameLength` | constant | 80 | Longest template, tier or request name. |
| `maxMatchTextLength` | constant | 400 | Longest `system` or `message` match text. |
| `builtInPrefix` | constant | `builtin.` | Id prefix of a built-in template. |

No environment variables, settings keys or injected dependencies are read. `removalProblem` reads the current locale through the system list formatter.

## Deep Linking

Not applicable: the files define data types and pure functions and have no URL handling or navigation.

## Localization

Every user-facing string is a hardcoded English literal with no localization lookup. The one locale-aware piece is the list in `removalProblem`, joined by the system list formatter for the current locale inside an English sentence. The template text forms (`claude:`, `provider:`), raw enum strings, tier and request ids and `unclassifiedId` are wire values and MUST NOT be localized. `ModelRouterTemplateDecodeError.newerFormat` names "Stenographer" in its reason.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; `ModelFamily.modelTitle`) | `Claude Haiku 5.5` / `Claude Sonnet 5.5` / `Claude Opus 5.5` / `Claude` | Title shown for a tier target naming a family |
| (none; `ModelRequestKindDTO.unclassifiedName`) | `Unclassified` | Display name of the kind that catches every unmatched request |
| (none; `defaultTiers`) | `Light` / `Standard` / `Heavy` | Default tier names |
| (none; `builtInCatalog`) | 44 request names, `Explore subagent` through `Command subagent` | Names of the built-in request kinds |
| (none; `builtIns`) | `Claude Code 2.1.296` | Name of the built-in template |
| (none; `ModelRouterTemplateDecodeError.reason`) | `not a template file` | File is not a template |
| (none; `reason`) | `made for a newer Stenographer (format N)` | File format above 3 |
| (none; `reason`) | `N of its request definitions can't be read, so the file was not imported` | Format-2 file with unreadable requests |
| (none; `reason`) | `its S can't be read, so the file was not imported` | Format-3 section unreadable |
| (none; `removalProblem`) | `<list> still go to <tier>. Choose another tier for them first.` / `<name> still goes to <tier>. Choose another tier for it first.` | A tier in use cannot be removed |
| `nameMissing` | `A template needs a name.` | Validation |
| `nameTaken` | `Another template already has that name.` | Validation |
| `nameTooLong` | `A template name can be at most 80 characters.` | Validation |
| `nameHasControls` | `A template name can't hold control characters, text-direction controls or line breaks.` | Validation |
| `badId` | `A template id is letters, digits, dots, dashes or underscores.` | Used by `ModelRouterTemplateStore` |
| `badVersion` | `A Claude Code version is whole numbers separated by dots, like 2.1.296.` | Validation |
| `backwardsRange` | `The first Claude Code version must not be after the last.` | Validation |
| `builtInReadOnly` | `Built-in templates can't be changed; duplicate one instead.` | Used by `ModelRouterTemplateStore` |
| `noSuchTemplate` | `That template no longer exists.` | Used by `ModelRouterTemplateStore` |
| `badRequestId` | `A request id is lowercase letters, digits and dashes, and can't be unclassified.` | Validation |
| `duplicateRequestId` | `Two requests have the same id.` | Validation |
| `requestNameMissing` | `Every request needs a name.` | Validation |
| `requestNameTaken` | `Two requests have the same name.` | Validation |
| `requestNameBad` | `A request name can be at most 80 characters, with no control characters or line breaks.` | Validation |
| `matchTextBad` | `The text a request is recognized by can be at most 400 characters, with no control characters.` | Validation |
| `noTiers` | `A template needs at least one tier.` | Validation |
| `badTierId` | `A tier id is lowercase letters, digits and dashes.` | Validation |
| `duplicateTierId` | `Two tiers have the same id.` | Validation |
| `tierNameMissing` | `Every tier needs a name.` | Validation |
| `tierNameTaken` | `Two tiers have the same name.` | Validation |
| `tierNameBad` | `A tier name can be at most 80 characters, with no control characters or line breaks.` | Validation |
| `requestTierMissing` | `Every request, and Unclassified, needs a tier.` | Validation |
| `requestTierUnknown` | `A request goes to a tier the template doesn't have.` | Validation |
| `requestTierStray` | `The request tiers name a request the template doesn't have.` | Validation |
| `tierTargetMissing` | `Every tier needs a model.` | Validation |
| `tierTargetBad` | `A tier's model must be a Claude model or an LLM Provider configuration.` | Validation |
| `tierTargetStray` | `The tier models name a tier the template doesn't have.` | Validation |

## Accessibility Options

Not applicable: the files have no visual surface, so Reduce Motion, Increase Contrast and Differentiate Without Color have nothing to act on.

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: no UI. |
| Increase Contrast | Not applicable: no UI. |
| Differentiate Without Color | Not applicable: no UI. |

## Feature Flags

Not applicable: the files read no flag. Whether the router is on is data the types carry (`ModelRouterPreferencesDTO.enabled`, `ModelRouterStatusDTO.enabled`), stored and enforced by the daemon, not a feature flag of this code.

## Analytics

Not applicable: the files emit no analytics events. `ModelUsageRowDTO` carries usage counts the daemon computes for its own router report; this code only holds them.

## Privacy

- **Data collected**: None by this code. The types carry what callers fill in: template ids and names, match text for system prompts and user messages (`system`, `message`), provider configuration names and model ids, a Claude Code version taken from a user agent, and token counts. The built-in match texts are sentences of Claude Code's own prompts, not user content.
- **Storage**: None; the types are in-memory values. `encodedFile` produces bytes that `ModelRouterTemplateStore` writes; persistence is that store and the daemon's database.
- **Transmission**: The values travel between the daemon and its local clients as JSON. `ModelRouterProviderDTO` is declared secret-free: it carries no API key and no URL.
- **Retention**: Not applicable at this layer; retention is the daemon's.

## Logging

Not applicable: the files contain no log calls. Failures surface only as a nil result (`ModelTierTarget.init`, `ClaudeCodeVersion.init`, `LossyDecoded.value`, `select`), a `false` (`isValidId`), a refusal sentence (`problem`, `removalProblem`), a `ModelRouterTemplateDecodeError` (`decodeFile`), a thrown decoding error, or empty data (`encodedFile`). The doc comment on `problem` records that names are printed raw by `steno router` and copied into every routing-log row, which is why names are screened.

| Event | Level | Message |
|-------|-------|---------|
| (none) | — | — |

## Platform Notes

- **SwiftUI**: The source is plain Swift in `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/Wire/ModelRouterDTOs.swift` and `ModelRouterTemplates.swift`, nested in an `extension Sessions` namespace, with no SwiftUI dependency. Swift-specific points a port must reproduce deliberately: synthesized `Codable` for the DTOs (unknown keys ignored, nil optionals omitted on encode); the hand-written template decoder with paired snake and converted camel `CodingKeys`; `UUID(uuidString:)` accepting either case while `uuidString` prints uppercase; `String.count` counting grapheme clusters for the 200, 80 and 400 caps; `Unicode.Scalar.Properties.generalCategory` for the denylist; `ListFormatter.localizedString(byJoining:)` for the removal sentence; `JSONSerialization` pre-inspection in `decodeFile`; and `try?` inside `LossyDecoded` to swallow one element's error. A SwiftUI template editor would bind to the four parts and show `problem` and `removalProblem` sentences.
- **Compose**: Port to Kotlin with `kotlinx.serialization`: `@Serializable` enums with `@SerialName`, data classes with nullable fields defaulting to `null`, and `Json { ignoreUnknownKeys = true; explicitNulls = false }`. The template needs a custom `KSerializer` (or decode to `JsonObject` first) to branch on `format`, accept both key spellings and throw a typed section error. `ModelTierTarget` is a `sealed interface` with `parse(text)`; `ClaudeCodeVersion` is a `Comparable` data class over a padded `List<Int>`. Count lengths with `BreakIterator.getCharacterInstance()`, test categories with `Character.getType` (`CONTROL`, `LINE_SEPARATOR`, `PARAGRAPH_SEPARATOR`), and join lists with `android.icu.text.ListFormatter`.
- **React/Web**: Port to TypeScript as string-literal unions, interfaces with optional properties, and a discriminated union for the tier target. `decodeFile` becomes a function over `JSON.parse` output that checks `typeof object.format === 'number'` and branches by format, returning a `{ ok: true, template } | { ok: false, error }` result. Count lengths with `Intl.Segmenter` in `grapheme` mode, test categories with `/\p{Cc}|\p{Zl}|\p{Zp}/u` plus the bidi code points, join lists with `Intl.ListFormat`, and use `/^[a-z0-9][a-z0-9-]{0,63}$/` for ids. Stringify with sorted keys and two-space indentation to match `encodedFile`.
- **AppKit / UIKit**: Identical to the Swift source; the types are Foundation-only and link into AppKit or UIKit targets unchanged. `modelTitle` would back an `NSPopUpButton` or `UIMenu` item title; validation sentences would back an alert or inline error.
- **WinUI 3**: Port to C# records under a `Sessions` static class, serialized with `System.Text.Json`. Enums use `JsonStringEnumConverter` with `JsonStringEnumMemberName`; nullable properties with `JsonIgnoreCondition.WhenWritingNull` reproduce nil omission, and unknown members are ignored by default. `ModelRouterTemplateDTO` needs a custom `JsonConverter<ModelRouterTemplateDTO>` that loads a `JsonDocument`, reads `format` with `JsonElement.TryGetInt32`, tries `claude_code` then `claudeCode` (and the other pairs), and throws a typed `ModelRouterTemplateDecodeException` carrying the section title; `DecodeFile` returns a result record rather than throwing. Write with `JsonSerializerOptions { WriteIndented = true }` and emit keys in ordinal order to match sorted output. `ModelTierTarget` is an abstract record with `ClaudeTarget` and `ProviderTarget(Guid Id, string? Model)` plus `TryParse`; use `Guid.TryParseExact(s, "D", out var g)` and print `g.ToString("D").ToUpperInvariant()`. `ClaudeCodeVersion` implements `IComparable<ClaudeCodeVersion>` and `IEquatable` over an `int[4]`, parsing pieces with `int.TryParse(piece, NumberStyles.None, CultureInfo.InvariantCulture, out var n)` after an ASCII-digit check (`char.IsAsciiDigit`). Count lengths with `StringInfo.LengthInTextElements`, screen scalars with `string.EnumerateRunes()` and `Rune.GetUnicodeCategory` (`Control`, `LineSeparator`, `ParagraphSeparator`) plus the bidi code points. .NET has no locale list formatter, so the removal sentence's join needs a small per-culture helper (or ICU through `Windows.Globalization`), which is a divergence from the source. `Select` is a LINQ query: `Where` covered, `OrderBy` preferred, built-in, `StringComparer.OrdinalIgnoreCase` name, ordinal id, `FirstOrDefault`. Immutable `record` types with `init`-only properties give the read-only DTOs the same thread safety as `Sendable`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/Wire/ModelRouterDTOs.swift` | confirmed (1.1.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/Wire/ModelRouterTemplates.swift` | confirmed (1.1.0) |

## Design Decisions

**Decision**: `ModelTierTarget` is not `Codable`; it is stored and sent as a string (`claude:<family>` or `provider:<uuid>[/<model>]`) and parsed with a failable initializer.
**Rationale**: A template's `tier_targets` map holds plain strings, so a stored target that no longer parses fails template validation with one sentence (`tierTargetBad`) instead of failing the decode of the whole template; an unknown but well-formed provider UUID is still accepted, and the test comment says it "falls back when routing".
**Approved**: pending

**Decision**: Only the first `/` after `provider:` separates the UUID from the model id; the rest of the text, slashes included, is the model.
**Rationale**: The source comment says "A model id may itself hold slashes (`org/model`), so only the first one separates."
**Approved**: pending

**Decision**: Names, match texts and provider model ids are screened by one denylist (`isRefusedInName`) and capped by length in characters.
**Rationale**: The comment in `problem` says the name "is printed raw by `steno router` and copied into every routing-log row, so nothing may drive a terminal, reorder the text around it, break a line or bloat a row"; the `isRefusedInName` doc comment says it is a denylist "so emoji (variation selectors, ZWJ sequences) and accents typed as combining marks stay allowed".
**Approved**: pending

**Decision**: `ModelFamily.other` exists but has no `size`, and `claude:other` does not parse.
**Rationale**: A Claude model id that names no known family still needs a family value, but such a model is "never routed": routing compares by size and only ever sends a request down the ranking.
**Approved**: pending

**Decision**: `ModelRouterPreferencesDTO` is a partial write in which every field is optional and nil means unchanged.
**Rationale**: The doc comment: a caller "sends only what it means to change and never reads-then-writes back what another writer may have changed meanwhile".
**Approved**: pending

**Decision**: Stored data is lenient and files are all or nothing: the plain decoder drops a bad format-2 request, while `decodeFile` refuses the same file with `unreadableRequests`.
**Rationale**: The `decodeFile` doc comment: "Unlike stored data, a file is all or nothing". Stored templates must keep loading after a format change; an imported file the user can fix is better refused with a count than imported short.
**Approved**: pending

**Decision**: A format-3 section that is present but unreadable throws `unreadableSection`, while an absent one takes its default.
**Rationale**: The decoder doc comment: "a part that is missing gets the default, and one that can't be read throws `.unreadableSection`, never a template short of it."
**Approved**: pending

**Decision**: Older formats are upgraded on decode (`format = max(stored, 3)`); format 1 takes the built-in's four parts and format 2 has its per-request `tier` split into `request_tiers` with the default tiers and targets.
**Rationale**: The decoder doc comment describes each conversion; the encoder writes only the format-3 keys, so a re-saved template is format 3.
**Approved**: pending

**Decision**: The template decoder accepts both `claude_code` and `claudeCode` (and the same pairs for `request_tiers`, `tier_targets`, `unclassified_tier`) and always encodes the snake-case key.
**Rationale**: The `CodingKeys` comment: "The same key after the XPC/HTTP decoder's snake-case conversion has renamed it." Files on disk use snake case; a decoder with a snake-case conversion presents the converted key.
**Approved**: pending

**Decision**: An unknown request id, and `unclassified`, default to the `heavy` tier.
**Rationale**: `defaultTierId` doc comment: "anything else (and unclassified) heavy"; since routing only sends a request down the ranking, a request the template does not recognize stays on the largest default tier.
**Approved**: pending

**Decision**: Template selection prefers a covering template, ordered preferred, built-in, name, id; with no cover it falls back to the template reaching the latest version and marks the result as a fallback.
**Rationale**: The `select` doc comment: "The template whose range covers `version`; failing that, the one reaching the latest version." `isFallback` lets the status (`inUseIsFallback`) say so.
**Approved**: pending

**Decision**: `encodedFile()` returns empty data instead of throwing.
**Rationale**: The template holds only strings, integers, arrays and string maps, which the encoder always encodes; the non-throwing signature keeps callers simple. The cost is that a future field that could fail to encode would vanish silently, which is technical debt to revisit if the shape grows.
**Approved**: pending

**Decision**: `LossyDecoded` drops a bad array element rather than failing the array, and decodes through the surrounding decoder.
**Rationale**: The doc comment: one bad element is dropped rather than the whole array, and decoding in place "keeps the decoder's key strategy, unlike re-encoding the element". `decodeFile` still counts the drops.
**Approved**: pending

**Decision**: `ModelRouterStatusDTO` and `ModelRouterProviderDTO` make every field added after the first version optional.
**Rationale**: A client can talk to an older daemon (`testPreferencesAndStatusDecodeWithoutTheNewFields` decodes a status of only `enabled` and `providers`); `models` is documented as "nil from a daemon that sends none".
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | Access Patterns |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | partial | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |

`separation-of-concerns` passes because the files hold only values and pure logic: file I/O and preference application are `ModelRouterTemplateStore`, status assembly is `AccountRouterServer`, and condition matching is the routing policy. `unit-test-coverage` is partial: `ModelRouterTemplatesTests` covers version parsing, user-agent extraction, the built-in template, all three format conversions, file refusals, every validation sentence, the scalar denylist and both selector paths, and `ModelRouterSettingsTests.testIdRules` covers `isValidId`; but `ModelTierTarget` parsing is exercised only through validation and round-trips, and `ModelFamily.size`, `modelTitle`, `providerId`, the 200-character model cap, the 400-character match-text cap and `LossyDecoded` on its own have no direct test. `explicit-error-handling` is partial: `decodeFile` returns a typed error with a reason and `problem` returns a sentence, but `ModelTierTarget.init`, `ClaudeCodeVersion.init` and `LossyDecoded` report failure as a bare nil and `encodedFile` turns an encoding error into empty data. `api-design-conventions` passes: optional fields with nil defaults, `Identifiable` by `id`, documented text forms and a versioned template format keep the wire additive and backward compatible. `data-integrity` passes because a file is refused rather than imported short (`unreadableRequests`, `unreadableSection`) and validation requires every request and tier to be mapped with no stray keys. `graceful-degradation` passes because stored templates from formats 1 and 2 convert instead of failing, absent format-3 sections take defaults, and selection falls back to the latest-reaching template with `isFallback` set. `input-sanitization` passes because names, match texts and model ids are length-capped and screened for control, bidi and separator scalars, and ids are restricted to a 64-character ASCII pattern. `data-minimization` passes because `ModelRouterProviderDTO` carries no key or URL. `no-hardcoded-strings` fails because every validation sentence, decode reason, display name and the removal sentence are English literals with no localization lookup. `locale-aware-formatting` is partial: the removal sentence joins names with the current locale's list formatter, but the surrounding sentence and its singular and plural forms are fixed English. `unicode-support` passes because every length cap counts grapheme clusters and the denylist keeps emoji and combining marks allowed.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.0 | 2026-11-21 | Mike Fullerton | Cover ModelRouterTemplates.swift: Claude Code versions, template formats 1-3 and file codec, validation sentences and denylist, template selection; drop Reference Implementations section |

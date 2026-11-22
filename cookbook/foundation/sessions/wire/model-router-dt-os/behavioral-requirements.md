
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


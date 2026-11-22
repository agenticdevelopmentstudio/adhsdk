
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


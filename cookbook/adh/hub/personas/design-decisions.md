
**Decision**: the model lists a screen shows come from the service row, annotated with `available`
and `offered`, not from the live model route.
**Rationale**: the models table and the persona editor both already read the service row's
cached models, so annotating the row reaches every screen with one change. Names the provider no
longer lists are appended with `offered: false` so a switched-off name stays visible and can be
switched back on.
**Approved**: pending

**Decision**: the provider UI moves to `@adh-sdk/ai-settings`, and the personas package re-exports
`ServicesSection`, `useUserServices` and `PERSONA_SERVICES_CACHE_KEY` for existing hosts until the
hub foundation's Cleanup phase (the "Cleanup (after the owner deploys)" section of
`docs/planning/2026-11-18-hub-foundation-phase-checklist.md` in the planning repo) removes them.
**Rationale**: AI Settings is no longer a personas concern, but hosts import these names from
personas today; the re-exports (the same objects) keep them working. The cache key keeps its name
and value so the admin host that shares the cache entry is untouched.
**Approved**: pending

**Decision**: the persona editor keeps the draft's switched-off model as the current value,
labelled "(not available)" with an inline note, instead of dropping it from the select.
**Rationale**: a select with no matching option would silently change the model on the next save
of an unrelated field. That carve-out is only for a model the persona was already saved on: when
the user picks another service, a model the new service has switched off is cleared like one it
does not list, because carrying it over would select a model the user cannot use. The reset runs in
the Service select's change handler rather than an effect, so opening a persona never clears it.
**Approved**: pending

**Decision**: `Persona.cannedChat`/`.chatStatus` are typed as the Hub `JSONValue` (with
hand-written `Decodable`, cross-`.int`/`.number` equality, and `hash(into:)`), not the simpler,
unrelated `JSONValue` under `Sync/`.
**Rationale**: the Hub variant's hand-written equality treats an integer JSON number and a
floating-point JSON number as the same value — a documented past-bug fix for round-tripping data
that a naive synthesized `Equatable` would treat as changed when it was not. Passing the tree
through opaquely (rather than decoding it into `CannedChatConfig`/`ChatStatusConfig` structs, as
the web does) avoids maintaining a second, potentially-diverging strongly-typed mirror on the
Apple side for data this module never reads.
Platform scope: Apple/Swift — this decision concerns this platform's own `JSONValue`
implementation choice and equality semantics; a port only needs to preserve the observable
behavior (opaque pass-through, with numeric-type-tolerant equality if it implements equality at
all).
**Approved**: pending

**Decision**: `PersonasModule.supportedFacetIDs` implements only 5 of the 13 facets declared in
`PersonasModule.facets`; the other 8 render a fixed "not available in this version" notice
instead of a form.
**Rationale**: the rail's shape (list-then-facets) is stable and worth shipping ahead of every
facet's editor being ready; showing the full rail with an honest notice on unfinished facets
avoids either hiding the facet's existence or exposing a half-built form.
Platform scope: Apple — describes the Apple facet rail's current rollout state; a port's own
facet coverage is a separate rollout decision.
**Approved**: pending

**Decision**: `resolveChatStatus` resolves `words` as a union (tagged rows plus untagged rows)
but resolves `icons` exclusively (first matching set only), even though both fields resolve
through the same fallback-chain shape.
**Rationale**: the source's own comments record that an earlier exclusive-only word chain drew
from a one-element list forever once a kind was tagged, so words changed to union; icons stayed
exclusive because a union there would let an untagged glyph set interleave frame-by-frame with a
tagged one — exactly the continuity break the glyph exists to avoid. The asymmetry is a documented
fix on one side and a documented constraint on the other, not an oversight.
**Approved**: pending

**Decision**: `api.personas.update` always sends the full `PersonaBody` including `slug`, and a
changed `slug` IS how a persona is renamed — there is no separate rename endpoint, and the former
follow-up `identifiersApi.rename` call (and its 404-recovery branch) has been removed.
**Rationale**: the source's comment records that the follow-up rename was a SECOND rename of a
handle the update's own cascade had already moved, landing on a now-taken target and reporting a
successful rename as a 409 failure; a single call has no such half-landed window to recover from.
Platform scope: Web — this decision traces the web client's own evolution away from a
since-removed follow-up rename call; a port need only ensure its own persona-rename path is a
single atomic update, not two calls.
**Approved**: pending

**Decision**: `InterestDocumentRow` declares every column of the backend's `content.markdown`
row (23 fields), not just the `id`/`title`/`content` this feature reads.
**Rationale**: the source's comment records that an earlier five-field fixture looked enough like
the wire to hide a real envelope bug; declaring the true shape (and true nullability) lets any
caller reaching for an undeclared field get an honest answer from the type rather than a
convenient subset that quietly diverges from what the server actually sends.
Platform scope: Web — this decision concerns this platform's own row-type declaration; a port
only needs to model the same true nullability of the corpus row, not this specific interface
name.
**Approved**: pending

**Decision**: `canDemoChat`'s ink check tests only for a non-blank `source` string and never
compiles the ink script.
**Rationale**: there is no ink compiler on the client, and the backend's own `canClaim` also does
not compile the script before deciding a demo exists — keeping both sides at "does it have
something to say" rather than "does it compile" means a syntax error cannot make the two
implementations disagree about whether a persona demos at all.
**Approved**: pending



**Decision**: Reading workspaces subscribes the reader's query client to
change announcements, once per client, counted, and only for announcements
another copy of the package made.
**Rationale**: From `useWorkspaces`' doc comment: the announcement already
invalidates this copy's entry directly, but "a host that bundles a second
physical `@adh-sdk/data` has a second toolkit client, and the window event
is the one announcement every copy hears". A second invalidation "is NOT
harmless: react-query's `invalidateQueries` cancels the refetch in flight
and starts another, so each extra sweep is an extra request". And "the
header menu, the rail and a gate can all read at once, and a subscription
each would sweep the one shared entry once per reader", so the subscription
is counted, "so the last reader to unmount removes it".
**Approved**: pending

**Decision**: One entry holds every row, teams included; a caller that wants
fewer rows filters what it gets.
**Rationale**: From the doc comment: "a caller that wants fewer rows (a
satellite: no teams) filters what this returns, so every switcher shares
one entry of all rows". `workspacesApi.list()`'s owner subset is a
different shape and keeps its own key.
**Approved**: pending

**Decision**: The every-row read state does not retry.
**Rationale**: From the doc comment: "No retry: the menu shows the failure,
and a second try only delays it."
**Approved**: pending

**Decision**: The composite id carries the type, and is never decoded back
into a slug.
**Rationale**: From `workspaceCompositeId`'s doc comment: "A slug alone
isn't unique across TYPES", yet the id is "NOT unique on its own either: a
team's slug is unique only within its owner". A menu gets unique ids only
because the header's workspaces feed first keeps one row per slug, and "the
feed maps a picked id to its row's slug with its own lookup over those same
kept rows".
**Approved**: pending

**Decision**: The list label reads every type by its own name, and falls back
to `My Workspace` or `Workspace` only for a blank name.
**Rationale**: From `workspaceListLabel`'s doc comment: the backend already
names the individual workspace after its owner, "so a personal workspace
shows the USER'S NAME rather than a generic 'My Workspace'". The blank
fallback "is load-bearing, not defensive noise": the backend's nullish
coalescing passes an empty display name through as `''`, which every
consumer treats as present, "so it is also the only place that can refuse
to return nothing". One function, "so all those surfaces can never drift".
**Approved**: pending

**Decision**: The first row of each slug is the only one offered.
**Rationale**: From `firstWorkspacePerSlug`'s doc comment: the hub resolves
a bare `/<slug>` with the first matching row of a priority-ordered list,
"so of the rows sharing a slug only the first can ever be opened. Offering
the others lists a row that opens its namesake, and a menu that marks the
current row by slug highlights all of them at once."
**Approved**: pending

**Decision**: The preference row is one shared item-cache entry with a
constant id, and its browser-cache seed is read on every render.
**Rationale**: From the doc comments: "two keys would let a pick in the
header leave `/home` resolving the old preference from its cache"; the id is
constant because the item hook's tenant scoping "already separates one
signed-in caller from the next". The seed is read each render because "the
cache is written by sign-in, sign-out and other tabs over this hook's
lifetime, and a copy taken at mount would keep showing a previous session's
slug".
**Approved**: pending

**Decision**: A failed preference write is dropped silently.
**Rationale**: From `choose`'s doc comment and the catch: "A failed PUT
leaves the choice standing locally; it is retried by the next pick, not by
this call", and "Silent, deliberately: the caches already carry the
choice."
**Approved**: pending


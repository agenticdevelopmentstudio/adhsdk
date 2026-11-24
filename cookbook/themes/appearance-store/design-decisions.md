
**Decision**: Hold the preferences in a module-level external store read with `useSyncExternalStore` instead of a React Context and Provider.
**Rationale**: The pre-paint script already applies the cached prefs before hydration, so no Provider is needed to supply first values. The module is imported by every site through the shared auth provider, so it must add no mounting requirement. The in-source comment states both reasons.
**Approved**: pending

**Decision**: Treat `localStorage` as a cache of the server's prefs, and make `adoptAppearance` replace rather than merge.
**Rationale**: The prefs follow the person across the family's many domains, so the server is the truth. A merge could leave another user's cached value in a field the server left unset. The in-source comment gives this reason.
**Approved**: pending

**Decision**: `resetAppearance` clears the cache instead of writing the defaults.
**Rationale**: Leaving a stored value would let the next person on that browser inherit the previous user's theme through the pre-paint script.
**Approved**: pending

**Decision**: Once any scope has mounted, paint only while a scope is mounted.
**Rationale**: The OS listener lives for the whole app, and `adoptAppearance` can resolve after the reader left a scoped route. A client navigation keeps the same `<html>`, so painting then would put the prefs on a page (the site template's frame) that never asked for them. A site that never mounts a scope keeps the earlier always-paint behavior.
**Approved**: pending

**Decision**: Probe `window.matchMedia` and the query's `addEventListener` at module scope instead of calling them.
**Rationale**: The module is in every site's import graph and runs this at load; a missing `matchMedia` (a jsdom test renderer was the case that caught it) or a Safari before 14 query with only `addListener` would make the import throw over a cosmetic preference. Absent means no OS signal, so `auto` resolves to light.
**Approved**: pending

**Decision**: Re-resolve only the `dark` class on an OS change; leave reduced motion and contrast to CSS media queries.
**Rationale**: Those two prefs have `auto` and `default` values that remove their attributes, so the browser's own queries govern with no JavaScript.
**Approved**: pending

**Decision**: Do not validate `set` patches or `adoptAppearance` input, and do not listen for `storage` events.
**Rationale**: Normalisation happens at the boundary that receives untrusted data (the cache read, and `AppearanceSync` before adopting); the store trusts its typed callers. Cross-tab sync is absent from the source. Both are recorded here as facts so a port does not assume them.
**Approved**: pending

**Decision**: Colour mode is honoured in every environment, production included.
**Rationale**: Per the comment on `applyAppearance`, a production lock to dark would make the saved setting do nothing where it matters most, now that every site reads it.
**Approved**: pending


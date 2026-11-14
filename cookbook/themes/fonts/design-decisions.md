
**Decision**: The preload list is derived from the same manifest the css build reads, with no hand-written paths.
**Rationale**: The module's header states a preload can then never point somewhere the css does not, nor carry a filename that no longer exists.
**Approved**: pending

**Decision**: Only the three CORE cuts, italic included, are preloaded; EXT cuts never are.
**Rationale**: CORE cuts carry a page's layout and the italic accent word of the landing heading sits above the fold. EXT cuts are fetched lazily by `unicode-range`, so preloading them would add bytes to every first paint.
**Approved**: pending

**Decision**: Preloads are same-origin, absolute paths.
**Rationale**: The browser then starts the fetch while parsing `<head>` on the connection that delivered the html, rather than after a third-party stylesheet is fetched and parsed, which is the difference between the webfont arriving before first paint and after it.
**Approved**: pending

**Decision**: The module does no validation of the manifest or of file presence.
**Rationale**: The generator owns the manifest and the consumer test in the adh package asserts shape, css agreement and file presence, so a second check here would duplicate it. The cost is that a missing byte file is silent in the page (see Stale paths in Edge Cases).
**Approved**: pending


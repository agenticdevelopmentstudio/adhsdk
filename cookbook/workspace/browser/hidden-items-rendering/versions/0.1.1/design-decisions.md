
**Decision**: one style element of `display: none !important` rules, not a
script that removes or hides matching nodes.
**Rationale**: Style rules apply to content added later with no observer,
and turning an entry off restores the element exactly; `!important`
outranks the page's own styles. This mirrors Hide Images
(`BrowserHiddenImages`), keeping one pattern for page styling (`dry`).
**Approved**: pending

**Decision**: each rule is inserted on its own, guarded, rather than set as
one block of text.
**Rationale**: In one text block, a selector the engine rejects can drop
the rule around it; inserting rules one by one confines a bad selector to
its own rule.
**Approved**: pending

**Decision**: the style goes into every frame, as Hide Images' does.
**Rationale**: Builder's choice. A distracting item can sit in a same- or
cross-site frame; site matching is decided once for the pane's address,
and frames follow it.
**Approved**: pending

**Decision**: the style runs in the page's content world.
**Rationale**: Builder's choice. A style element is drawn wherever it is
added, so the world only decides which scripts can touch it; the page
world matches Hide Images. The selectors were picked from the page itself,
so the page learns nothing new from them.
**Approved**: pending


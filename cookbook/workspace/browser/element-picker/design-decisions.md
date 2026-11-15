
**Decision**: our own injected script with @medv/finder, not WebKit's
targeted-element API.
**Rationale**: Safari's Distraction Control uses `_WKTargetedElementInfo`
and `adjustVisibility`, which are private API and would be rejected from
the Mac App Store; they also only hide visually, and the agent list needs
selectors of our own anyway. Finder is MIT, about 1.5 kB, and gives the
shortest unique selector with pluggable filters.
**Approved**: pending

**Decision**: two scopes, This item and All items like it, with no
specificity slider.
**Rationale**: Arc's "Zap this" / "Zap all related" model is
understandable without knowing CSS; uBlock's depth and specificity sliders
are too technical, and This item alone is fragile and tedious.
**Approved**: pending

**Decision**: a pick applies site-wide, under the page's host pattern.
**Rationale**: Safari and uBlock both save per host; the same distraction
appears on every page of a site.
**Approved**: pending

**Decision**: the picker runs in its own content world, not the automation
world.
**Rationale**: The page must not see or interfere with the picker, and the
automation world belongs to the agent's tools; a world per purpose keeps
either from breaking the other (`separation-of-concerns`).
**Approved**: pending

**Decision**: the dialog is a movable modal window, not a sheet.
**Rationale**: A sheet covers the top of the page, which is often where the
picked item is; uBlock's dialog is draggable for the same reason.
**Approved**: pending

**Decision**: the looser selector is refused above half of the page's
elements.
**Rationale**: A selector like `div` would blank the page; half is a simple
cut that never refuses a real "items like it" (cards, ads, rows) on a page
of any size.
**Approved**: pending

**Decision**: no keyboard traversal for choosing an element.
**Rationale**: Builder's choice. Every prior picker is pointer-driven; the
saved entries are fully manageable from the keyboard in the popover.
**Approved**: pending


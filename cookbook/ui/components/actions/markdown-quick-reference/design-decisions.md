
**Decision**: The syntax list is a module-level constant inside the component
rather than a prop.
**Rationale**: It is a fixed reference; a single authoritative cheatsheet
(DRY) is better than letting each consumer pass a divergent list.
**Approved**: pending

**Decision**: Built on the shared `SyntaxQuickReference` shell, which itself
is built on `Popover` (not a bespoke overlay or the modal `Dialog`).
**Rationale**: Reuse the platform dismissal + focus-restore behavior; a
lightweight, non-modal reference should not trap focus or dim the page.
**Approved**: pending

**Decision**: A fixed `aria-label` independent of `triggerLabel`.
**Rationale**: Keeps the accessible name stable for tests and assistive tech
even when a consumer shortens the visible label.
**Approved**: pending

**Decision**: Keep the markdown snippets fixed, but let a consumer override the labels, `title` and `ariaLabel`.
**Rationale**: The snippets are literal markdown and must not diverge between consumers, while the labels are prose a locale must translate; tying both to one fixed constant makes the localization gap permanent. The trade-off is a wider props surface.
**Approved**: pending

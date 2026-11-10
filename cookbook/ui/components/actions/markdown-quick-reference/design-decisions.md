
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


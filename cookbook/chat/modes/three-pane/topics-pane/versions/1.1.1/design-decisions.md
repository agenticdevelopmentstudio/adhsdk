
**Decision**: Apply visibility and active state via CSS classes (`pc-pane-visible`/`pc-pane-hidden`, `active`) rather than inline styles.
**Rationale**: Delegates appearance control to stylesheets, supporting theme switching and design system consistency.
**Approved**: pending

**Decision**: Identify the active topic by its array index rather than by object identity or a unique key property.
**Rationale**: Keeps selection state simple and couples it directly to list order.
**Approved**: pending

**Decision**: Render a `ConnectorAnchor` child inside each topic button.
**Rationale**: Indicates this component participates in a visual linking/diagramming system where topics connect to other pane elements.
**Approved**: pending

**Decision**: Leave `activeIndex` allowed to be `undefined` or out-of-bounds, with no default active selection.
**Rationale**: Leaves the choice of a default selection to the parent component's own logic.
**Approved**: pending

**Decision**: Accept the connascence-of-position risk of index-based selection (`activeIndex`, `onSelectTopic(index)`) rather than keying selection to a stable identifier such as `messageIndex`.
**Rationale**: Matches the source's array-index selection model described above; reordering or inserting topics can silently shift which topic `activeIndex` points at. This is recorded as known debt rather than fixed here, since the source does not implement stable-key selection.
**Approved**: pending


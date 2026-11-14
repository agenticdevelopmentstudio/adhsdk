
**Decision**: Apply visibility and active state via CSS classes (`pc-pane-visible`/`pc-pane-hidden`, `active`) rather than inline styles.
**Rationale**: Delegates appearance control to stylesheets, supporting theme switching and design system consistency.
**Approved**: pending

**Decision**: Render a `ConnectorAnchor` child inside each topic button.
**Rationale**: Indicates this component participates in a visual linking/diagramming system where topics connect to other pane elements.
**Approved**: pending

**Decision**: Leave `activeIndex` allowed to be `undefined` or out-of-bounds, with no default active selection.
**Rationale**: Leaves the choice of a default selection to the parent component's own logic.
**Approved**: pending

**Decision**: Identify the active topic by its array index (`activeIndex`, `onSelectTopic(index)`) rather than by object identity or a stable key such as `messageIndex`.
**Rationale**: Keeps selection state simple and matches the source's array-index model. The cost is connascence of position: reordering or inserting topics can silently shift which topic `activeIndex` points at. This is recorded as known debt rather than fixed here, since the source does not implement stable-key selection.
**Approved**: pending

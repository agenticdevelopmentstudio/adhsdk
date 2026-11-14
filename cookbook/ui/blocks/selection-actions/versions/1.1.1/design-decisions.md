
**Decision**: The component renders only its children (buttons and dividers) in a Fragment, with no container element of its own; it relies on the parent (ListHeader's actions slot) to provide layout and styling context.
**Rationale**: This keeps the component flexible and prevents nesting issues in toolbar contexts.
**Approved**: pending

**Decision**: The `requiresSelection` property defaults to `false` (or is omitted), meaning actions are enabled by default.
**Rationale**: This allows "New" and other standalone actions to work without requiring a selection; actions that genuinely need a selection must explicitly declare `requiresSelection: true`.
**Approved**: pending

**Decision**: Delete is always behind a confirmation modal, never immediate.
**Rationale**: This reflects the destructive nature of deletion and aligns with common UX patterns for irreversible actions.
**Approved**: pending

**Decision**: Dividers use the ARIA `separator` role rather than being purely visual.
**Rationale**: This ensures users of assistive technology understand the structural grouping of action buttons.
**Approved**: pending

**Decision**: The component does not manage retry, undo, or error handling for action callbacks.
**Rationale**: Each action handler (and the `onDelete` callback) is fully responsible for managing its own error states, async operations, and side effects. This keeps Selection Actions lightweight and composable.
**Approved**: pending


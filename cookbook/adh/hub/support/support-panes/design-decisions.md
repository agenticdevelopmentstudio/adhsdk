
**Decision**: The customer's pane is one component for customers and hub users, chosen by `side`.
**Rationale**: The two views use the same routes under different prefixes, so one pane and one set of tests serve both.
**Approved**: pending

**Decision**: The viewer shows rows as text and has no edit controls at all.
**Rationale**: A grant is read-only in the design; a control that could never succeed would only mislead.
**Approved**: pending

**Decision**: The product admin pane starts the step-up (through the session's `stepUp` or an `onStepUp` prop) and the data client only recognises it (`isStepUpRequired`).
**Rationale**: Navigation belongs to the session provider; the pane decides where to return to.
**Approved**: pending

**Decision**: The strings are English literals in the components for now, with no localization layer.
**Rationale**: No hub pane is localized yet, so these follow the rest; the debt is paid when the hub adopts a localization layer, and **Localization** says what a port must do meanwhile.
**Approved**: pending


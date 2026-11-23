
**Decision**: The customer's pane is one component for customers and hub users, chosen by `side`.
**Rationale**: The two views use the same routes under different prefixes, so one pane and one set of tests serve both.
**Approved**: pending

**Decision**: The viewer shows rows as text and has no edit controls at all.
**Rationale**: A grant is read-only in the design; a control that could never succeed would only mislead.
**Approved**: pending

**Decision**: The product admin pane starts the step-up and the data client only recognises it.
**Rationale**: Navigation belongs to the session provider; the pane decides where to return to.
**Approved**: pending


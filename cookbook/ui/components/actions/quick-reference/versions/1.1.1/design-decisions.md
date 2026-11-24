
**Decision**: Build the component on the shared Popover primitive rather than reimplementing outside-click dismissal, Escape handling, and focus restoration.
**Rationale**: This ensures consistent behavior across the application and reduces code duplication — all popovers behave identically.
**Approved**: pending

**Decision**: Mark up entries as a definition list (`dl`, `dt`, `dd`) rather than a table or unordered list; the grid layout is applied via CSS (Tailwind), decoupling presentation from semantics.
**Rationale**: This gives each label-syntax pair explicit semantic meaning (term and definition) for assistive technology.
**Approved**: pending

**Decision**: Default the popover width to 20rem (`w-80`) and the column split to 7rem (labels) / 1fr (code), customizable via `contentClassName` and `columnsClassName`.
**Rationale**: These defaults fit common use cases (Markdown, code snippets); a language needing more or less space can override them per call site.
**Approved**: pending

**Decision**: Position the BookText icon at the inline-start of the trigger using the `data-icon="inline-start"` data attribute rather than hardcoding absolute positioning.
**Rationale**: This lets the icon participate in the button's icon-handling logic and flips correctly for RTL (left in LTR, right in RTL) without extra styling.
**Approved**: pending

**Decision**: Make `triggerLabel` optional so the trigger can be icon-only in space-constrained toolbars.
**Rationale**: When present, the label appears alongside the icon; when absent, the icon-only trigger still has an accessible name via `ariaLabel`.
**Approved**: pending

**Decision**: Render code values with `whitespace-pre-wrap` to preserve formatting (indentation, line breaks) in syntax examples.
**Rationale**: This is essential for code reference material, where exact formatting is part of what is being taught.
**Approved**: pending


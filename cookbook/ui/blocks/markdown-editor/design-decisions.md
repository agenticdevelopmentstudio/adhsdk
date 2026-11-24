
**Decision**: Upload reports `(text, fileName)` via `onUpload` instead of
mutating `value` itself.
**Rationale**: Keeps the editor body-only and reusable; the consuming form
decides whether an upload also sets a title or other fields (separation of
concerns).
**Approved**: pending

**Decision**: The quick-reference control is built in (default on) but
toggleable, and there is also a generic `toolbarExtras` slot.
**Rationale**: Common editors get the cheatsheet for free, while bespoke
toolbars can add controls (e.g. a spell-check toggle) without forking the
block.
**Approved**: pending

**Decision**: When `disabled`, the quick-reference control and `toolbarExtras`
stay enabled.
**Rationale**: The quick reference is read-only help that is harmless while the
body is locked, and `MarkdownQuickReference` takes no `disabled` prop; the
`toolbarExtras` content belongs to the consumer, who disables it themselves.
**Approved**: pending

**Decision**: The textarea id comes from `useId`, not a fixed string.
**Rationale**: A shared component must support multiple instances per page
without colliding the Label↔Textarea association.
**Approved**: pending

**Decision**: `EditorToolbar` is factored as its own exported primitive with
`role="toolbar"`.
**Rationale**: Reusable a11y-correct toolbar semantics for any editor surface,
and it keeps the block focused on composition.
**Approved**: pending


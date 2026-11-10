
- **Decision**: Take `getText`, not `text`.
  **Rationale**: A thunk resolves the payload at click time, so the copied text
  reflects the current filter/selection instead of a value frozen at render — the
  reason this affordance can sit next to a live, filtered table.
  **Approved**: pending

- **Decision**: Empty string means nothing copied.
  **Rationale**: `getText` signals "nothing to copy" by returning `""`, keeping the
  enabled/no-op decision inside the component so hosts never wrap it in a visibility
  conditional.
  **Approved**: pending

- **Decision**: Fail silently on clipboard errors.
  **Rationale**: `useClipboard` swallows write failures (insecure context, denied
  permission); a copy affordance that cannot copy simply does nothing rather than
  throwing or alarming the user.
  **Approved**: pending

- **Decision**: Compose the shared `Button` and `useClipboard` rather than a bespoke
  implementation.
  **Rationale**: Every "copy this" control is one component built on the family
  `Button` (outline/icon) and the shared hook, so styling and behavior stay identical
  everywhere instead of drifting per call site.
  **Approved**: pending

- **Decision**: Fix the success window at 1200 ms.
  **Rationale**: The success window is a deliberate constant (shorter than
  `useClipboard`'s 1500 ms default) so the check reads as a quick affirmation, not a
  lingering state; it is not a prop, to keep the feel consistent across call sites.
  **Approved**: pending

- **Decision**: Override the icon size to `size-6` instead of `Button`'s default.
  **Rationale**: The button overrides `Button`'s `size-8` icon square down to
  `size-6` (24px) so the control sits inline beside text or a label without
  dominating the row.
  **Approved**: pending


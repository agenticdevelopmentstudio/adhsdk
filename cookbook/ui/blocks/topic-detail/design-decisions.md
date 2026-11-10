
- **Decision**: The pane stays bare; `TopicRail` owns all header chrome (titled header, create `+`, footer, close button) via its own props, not the pane and not ad hoc consumer composition around the whole primitive.
  **Rationale**: Keeps the primitive reusable and focused (separation of concerns) while still giving every consumer the same chrome building blocks instead of reinventing them per call site.
  **Approved**: pending

- **Decision**: Collapse is intrinsic, not a config flag — there is no `collapsible=true/false` prop.
  **Rationale**: The site design treats collapsing to an icon strip as a core gesture to make room for the detail pane on desktop, so it is always available rather than opt-in.
  **Approved**: pending

- **Decision**: The component supports both controlled and uncontrolled collapse — pass `collapsed` + `onCollapsedChange` for external control (e.g. a hierarchical stack auto-minimizing ancestors), or omit them and let the component self-manage from `defaultCollapsed`.
  **Rationale**: Different call sites need different ownership of the collapse flag; supporting both avoids forcing every consumer through the same pattern.
  **Approved**: pending

- **Decision**: The rail measures its own intrinsic width and reports it via `onFit` instead of the parent guessing from character counts or a fixed number.
  **Rationale**: Only the component knows the full row anatomy (icon, label, sublabel, preview, trailing, delete button). Measurement is intrinsic (`max-content`), clamped to [MIN_FIT_RAIL, MAX_FIT_RAIL], and independent of the width the parent gives back, so there is no oscillation.
  **Approved**: pending

- **Decision**: While actively dragging the trailing edge, the rail's width transition is disabled so it tracks the pointer live; it re-enables on release.
  **Rationale**: Prevents janky visual lag during the drag and makes the resize feel responsive.
  **Approved**: pending

- **Decision**: The collapsed icon-only layout is always a fixed `COLLAPSED_RAIL` width (48px) — never measured.
  **Rationale**: Accessibility and simplicity: icon buttons have a predictable target size and no computation is needed for a layout that never varies.
  **Approved**: pending

- **Decision**: Every row is guaranteed a leading icon — a fallback neutral ring icon fills in when `icon` is omitted.
  **Rationale**: Keeps the collapsed icon-only strip readable: no blank slots, consistent visual rhythm.
  **Approved**: pending

- **Decision**: Preview text preserves the source's own line breaks (`whitespace-pre-line`) instead of collapsing to a single run-on paragraph.
  **Rationale**: A note rendered as one run-on paragraph reads nothing like the original content.
  **Approved**: pending

- **Decision**: When `inlineSublabel=true`, the label grows and truncates first; the sublabel shrinks and truncates after it.
  **Rationale**: Keeps the identifier visible when space is tight and lets metadata (the sublabel) yield first.
  **Approved**: pending

- **Decision**: Checking a batch checkbox is independent of selecting a row — the row's single-selection behavior is preserved underneath.
  **Rationale**: Ticking a box to include an item in a batch action should not disturb which item's detail pane is currently open; that independence is the point of batch mode.
  **Approved**: pending

- **Decision**: In covered style, clicking an already-selected row is a no-op (pure select, never toggle); non-covered lists keep the re-click-fires-`onSelect`-again behavior.
  **Rationale**: Covered rows are peeking siblings without a dismiss affordance, so re-clicking one is a selection reset, not a toggle — the two layouts have different physical metaphors.
  **Approved**: pending

- **Decision**: Prefetch never arms on the already-selected row, and disarm handlers stay unconditional so any armed timer is always cleared.
  **Rationale**: A prefetch is a guess about where the user is going next; the already-open item's data is already loaded, so warming it again would re-read it behind the pane the user is looking at, causing visible lag.
  **Approved**: pending

- **Decision**: When `onDelete()` throws, the confirmation dialog stays open without its spinner, rather than closing as on success.
  **Rationale**: The consumer owns the error message; leaving the dialog open lets the user retry or cancel without having to dismiss and reopen it.
  **Approved**: pending

- **Decision**: The blocked marker (amber dot) rides the row's icon rather than a trailing slot, and renders in expanded, collapsed, and covered layouts alike.
  **Rationale**: Trailing slots are hidden in collapsed/covered layouts — exactly where a user hunting for a greyed-out Save button most needs to see which topic is holding it down.
  **Approved**: pending

- **Decision**: `panePadding` is a single toggle on the pane, not a per-row concern.
  **Rationale**: Lets consumers opt into edge-to-edge rows without negative-margin hacks; the pane carries the padding once instead of duplicating inset CSS on each row.
  **Approved**: pending

- **Decision**: The component is a faithful 1:1 port of the source settings rail — CSS translated to utilities with `apt-*` tokens — so every consumer renders identically.
  **Rationale**: Any visual divergence from the reference implementation is unintended drift to fix, not an accepted feature or platform difference.
  **Approved**: pending


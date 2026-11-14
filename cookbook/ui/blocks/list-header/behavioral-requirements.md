
- **one-row-layout**: The header MUST render title (when set), filter field
  (when set), a flexible space, then actions — in that order — in one
  `ButtonBar` row. The flexible space is omitted when `search.grow` is true,
  because the growing field takes that room itself (see **filter-width-cap**).
- **controlled-filter**: The filter field MUST be fully controlled
  (`search.value` / `search.onChange` fired per keystroke) — the header never
  owns filter state.
- **optional-parts**: Title, filter, and actions MUST each be independently
  omittable; an absent part reserves no space.
- **filter-width-cap**: The filter field MUST be `min-w-0 flex-1` and capped at
  `max-w-xs` unless `search.grow` is true. When `grow` is true the cap MUST be
  removed and the field MUST take ALL the row's remaining width, so the trailing
  flex spacer MUST NOT render (a second `flex-1` beside the field would halve it).
  When `grow` is false the spacer renders and pushes `actions` to the right edge.
- **accessible-names**: The bar MUST take an `ariaLabel`; the filter field's
  accessible name defaults to `"Filter"` and is overridable via `search.label`.
- **autofocus-remount**: When `search.autoFocus` is true, the filter field MUST
  receive focus every time the header is newly shown (attached to the DOM); it
  MUST NOT receive focus again merely because the header re-rendered while it
  remains shown (e.g. a keystroke updating `search.value`).
- **touch-target-minimum**: The filter field MUST be at least 24×24 CSS px (WCAG 2.2
  AA); the native minimums (44×44pt on iOS, 48×48dp on Android) apply to ports and are
  listed in the Platform Notes. Sizing the `actions` is the consumer's job: `actions`
  is a consumer-supplied node the header cannot size (use the shared `Button` by default).
- **title-never-truncates**: The title MUST render at its full natural width — it is
  `shrink-0` with no `truncate`/ellipsis styling — so when the row is too narrow the
  filter field shrinks first, then actions, before the title is affected.
- **state-without-color**: The filter field MUST NOT rely solely on color to convey
  state: its focus ring (border plus ring) and its filled versus empty state MUST be
  distinguishable without color.

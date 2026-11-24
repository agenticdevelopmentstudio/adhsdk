
- **one-row-layout**: The header MUST render title (when set), filter field
  (when set), a flexible space, then actions — in that order — in one
  `ButtonBar` row.
- **controlled-filter**: The filter field MUST be fully controlled
  (`search.value` / `search.onChange` fired per keystroke) — the header never
  owns filter state.
- **optional-parts**: Title, filter, and actions MUST each be independently
  omittable; an absent part reserves no space.
- **filter-width-cap**: The filter field MUST be capped at `max-w-xs` unless
  `search.grow` is true, in which case it MUST flex (`flex-1`) to share the
  row's free space equally with the always-present trailing flex spacer
  between the filter and `actions` — the field exceeds `max-w-xs`, but an
  equally-sized gap remains before `actions`, so it does not reach them.
- **accessible-names**: The bar MUST take an `ariaLabel`; the filter field's
  accessible name defaults to `"Filter"` and is overridable via `search.label`.
- **autofocus-remount**: When `search.autoFocus` is true, the filter field MUST
  receive focus every time the header is newly shown (attached to the DOM); it
  MUST NOT receive focus again merely because the header re-rendered while it
  remains shown (e.g. a keystroke updating `search.value`).
- **touch-target-minimum**: The filter field and any action buttons MUST meet
  the platform's minimum touch/click target size: 44×44pt on iOS, 48×48dp on
  Android, or 24×24 CSS px per WCAG 2.2 AA on web.


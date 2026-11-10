
```
┌──────────────────────────────────────────────────┐
│ Title  [🔍 Filter…        ]        [+ New] [Del] │  ButtonBar strip
└──────────────────────────────────────────────────┘
```

- **Container**: The strip is the shared `ButtonBar` (recessed, `border-b`).
- **Title**: mono font, `text-xs`, `text-apt-text-muted`, non-shrinking left section.
- **Filter field**: shared `Input` component with `type="search"`, leading `Search`
  icon (`text-apt-text-muted` colored), constrained to `max-w-xs` unless `grow` is true
  (see **filter-width-cap**); when `grow` is true it is also `flex-1`, so it competes
  for free space equally with the flexible spacer below rather than filling it alone.
- **Flexible space**: A `flex-1` spacer always renders between the filter and actions,
  independent of `grow` — when `grow` is true, it and the (also `flex-1`) filter field
  split the row's free space evenly.
- **Actions**: Right-aligned content, no size constraint.
- **No raw hex colors**: All colors use `apt-*` design tokens.
- **No `!important` declarations**: Specificity is managed via composition.


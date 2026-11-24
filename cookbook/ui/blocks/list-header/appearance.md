
```
┌──────────────────────────────────────────────────┐
│ Title  [🔍 Filter…        ]        [+ New] [Del] │  ButtonBar strip
└──────────────────────────────────────────────────┘
```

- **Container**: The strip is the shared `ButtonBar` (recessed, `border-b`).
- **Title**: mono font, `text-xs`, `text-apt-text-muted`, non-shrinking left section.
- **Filter field**: shared `Input` component with `type="search"`, leading `Search`
  icon (`text-apt-text-muted` colored), `min-w-0 flex-1`, capped at `max-w-xs` unless `grow` is true
  (see **filter-width-cap**); when `grow` is true the cap is removed and it takes all
  of the row's remaining width.
- **Flexible space**: A `flex-1` spacer renders between the filter and actions unless
  `grow` is true — a growing field is the flex, and a second `flex-1` beside it would
  halve the field.
- **Actions**: Right-aligned content, no size constraint.
- **No raw hex colors**: All colors use `apt-*` design tokens.
- **No `!important` declarations**: Specificity is managed via composition.


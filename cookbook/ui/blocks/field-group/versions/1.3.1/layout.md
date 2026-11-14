
```
┌ section (rounded, bordered, recessed surface) ─────────────────┐
│  GROUP TITLE                              [ trailing accessory ]│  ← title row
│                                                                 │
│  ┌ Field ───────────────────────────────────────────────────┐ │
│  │ CAPTION / control / hint|error                            │ │
│  └───────────────────────────────────────────────────────────┘ │
│  ┌ Field ───────────────────────────────────────────────────┐ │
│  │ CAPTION / control / hint|error                            │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

- Root: `section` — `flex flex-col gap-3 rounded-lg border border-apt-border
  bg-apt-surface-2/40 p-3` (recessed card).
- Title row: `flex items-center justify-between gap-2`; the `<h3>` title on the
  `fieldCaptionClass`, the `trailing` node right-aligned via `justify-between`.
- Children: the `Field` rows follow the title row in the same column, separated by
  the section's `gap-3`.
- No raw hex; no `!important`; every color is an `apt-*` token.


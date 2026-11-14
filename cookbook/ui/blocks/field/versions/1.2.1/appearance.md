
```
LABEL CAPTION            ← uppercase mono, apt-text-muted (fieldCaptionClass)
┌───────────────────────┐
│  control (children)    │ ← Input / Select / Switch / Textarea / …
└───────────────────────┘
helper text below         ← hint: dim mono (apt-text-dim)
                          ← OR error: red mono (apt-red), replacing the hint
```

- Root, `layout="stacked"` (default): the shared `Label` as a vertical stack —
  `flex flex-col items-start gap-1.5` — so caption, control, and supporting line
  left-align in a column.
- Root, `layout="inline"`: the shared `Label` as a two-column grid — `grid
  grid-cols-[var(--apt-field-label-w,8rem)_minmax(0,1fr)] items-center gap-x-3
  gap-y-1` — with the caption right-aligned in column 1 (`justify-self-end
  text-right`), the control (and any sibling children) wrapped in one cell in
  column 2 (`flex min-w-0 flex-col gap-2`), and the supporting line also in
  column 2 (`col-start-2`). A group of inline fields shares one label column by
  setting `--apt-field-label-w` once on a wrapper; `FIELD_LABEL_GROUP_CLASS`
  (`[--apt-field-label-w:6.5rem]`) is the one width every inline group in the
  family agrees on, so sibling subtrees read the same source instead of each
  hardcoding a copy of `6.5rem`.
- Caption: `fieldCaptionClass` = `font-mono text-[0.7rem] uppercase tracking-wider
  text-apt-text-muted` (the platform's one caption treatment).
- Hint: `font-mono text-[0.7rem] text-apt-text-dim`.
- Error: `font-mono text-[0.7rem] text-apt-red` — same metrics as the hint, red
  tone, occupying the same slot.
- No raw hex; no `!important`; every color is an `apt-*` token.


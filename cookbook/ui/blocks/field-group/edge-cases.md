
- **no-trailing**: No `trailing` → the title row still lays out with `justify-between`, so the title
  sits at the left edge exactly as with an accessory present.
- **zero-children**: Zero `children` → an empty titled card renders (title row only); the group does
  not error on an empty body.
- **wide-trailing**: A `trailing` node wider than its slot shares the row via `gap-2`; the title
  (`h3`) does not truncate here — long titles wrap unless the caller constrains them.
- **non-field-children**: `children` need not be `Field`s specifically — any nodes stack — but the group is
  designed and spaced for `Field` rows.
- **node-title**: `title` is a `ReactNode`, so an inline glyph/badge in the title still renders with
  the caption treatment.



- Both `hint` and `error` set → `error` wins and the hint is not rendered (the
  error occupies the hint's slot, so the row height does not jump).
- For a field that already shows a `hint`, `error` toggling on/off swaps the
  single supporting line rather than stacking two lines, so validated forms
  don't reflow by an extra row. A field with no `hint` at all has no supporting
  line to begin with (**omit-supporting-line-when-empty**), so it gains a whole
  line the first time an `error` appears — the stable-height guarantee only
  holds once a `hint` is already occupying the slot.
- `label` is a `ReactNode`, so a caption may include an inline glyph or badge; it is
  still rendered with the caption treatment.
- Empty-string `hint`/`error` renders nothing (falsy), same as omitting it.
- The control is whatever `children` the caller passes; `Field` imposes no control
  type and forwards no value/validation.



Inherited unmodified from the text edit row — corner radius, padding,
font, background, foreground/text, border, shadow, and min/max size are
all as documented at
appearance ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)); this
component sets no font or color of its own on the label or the field; its
only color of its own is the accessory buttons' tint, below. The differences
this specialization introduces:

- **Masking**: while obscured, the field's characters render as the
  platform's built-in dot-mask glyphs rather than plain text (see
  **masks-entry-with-secure-field** and **stored-secret-shows-as-dots**).
- **Accessory buttons**: two borderless, image-only buttons after the field,
  right-aligned: copy (a copy glyph) and the eye (a reveal glyph while
  obscured, a conceal glyph while shown), each sized to the field's height and separated from
  the field and from each other by the row's standard spacing. Their tint is
  the theme's secondary text role; a disabled copy button is dimmed by the
  platform.
- **Min/Max size**: the field still fills the row's leftover width; the two
  buttons keep their intrinsic size and never compress.


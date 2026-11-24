
- The embedded `ListChooser` provides the combobox/listbox semantics: trigger `aria-haspopup="listbox"` + `aria-expanded`, the filter field `role="combobox"` with `aria-controls` / `aria-activedescendant`, and `role="listbox"` / `role="option"` rows. Focus moves to the field on open and returns to the trigger on close.
- The trigger is labelled by `ariaLabel`; the filter/add field by `inputLabel` (falling back to `ariaLabel`).
- Multi mode wraps the chips + trigger in a `role="group"` labelled by `ariaLabel`; each chip's remove control is a `<button>` with `aria-label="Remove <value>"`.
- Keyboard operability (arrows, Enter, Esc, OK/Cancel) is inherited unchanged from `ListChooser`.
- Minimum touch target size for trigger and chip-remove controls is expected to be at least 44×44 CSS px on web (WCAG 2.5.5; 24×24 CSS px is the 2.5.8 minimum; 44×44pt on Apple platforms) — see **min-touch-target-controls**; the source sets no explicit sizing for either control, so this rests on inherited styling rather than something the component enforces itself.



`Combobox` is a free-text input that reveals a popup of matching suggestions as
the user types. The input's text is the value; the suggestions are hints the user
may pick with the keyboard (Up/Down to move, Enter to pick, Esc to close) or the
pointer. It is the accessible replacement for the native `<datalist>` pattern used
ad hoc across sites, giving every site one styled, keyboard-correct autocomplete.

It wraps Base UI's headless `Autocomplete` primitive (`@base-ui/react/autocomplete`)
rather than hand-rolling the keyboard and ARIA: Base UI renders the input with
`role="combobox"` and manages `aria-expanded`, `aria-controls`, and
`aria-activedescendant`, case-insensitive substring filtering, and the floating
popup. The wrapper's job is purely to theme those parts with `apt-*` tokens and
expose a small controlled `value` / `onValueChange` API. It differs from
`ListChooser`, which is a disclosed chooser with a trigger, an always-visible list,
an add-new affordance, and an OK/Cancel commit step.


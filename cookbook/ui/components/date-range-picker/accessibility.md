
- **Role/trait**: Each field is a native `input` of type `date`, so the browser supplies the date-field role, the segment navigation and the calendar picker, the reason the source gives for choosing native fields.
- **Label requirements**: Each field has a visible label bound with `htmlFor` to the field's generated id, so the accessible name of the first field is "From" and of the second is "To".
- **Keyboard**: The component adds no key handling; keyboard operation is the native date control's.
- **State announcements**: The component announces nothing of its own; it has no error, loading or disabled state.
- **Minimum tap target**: NEEDS REVIEW: Not implemented in source. The component sets no height or hit area for the fields; the shared Input component gives each field `h-9` (36px, 2.25rem) and `w-auto`, and the source does not say whether 36px is acceptable. A check of the rendered date field against the platform minimum target size, such as 44pt on Apple platforms and 48dp in Material, would settle it.


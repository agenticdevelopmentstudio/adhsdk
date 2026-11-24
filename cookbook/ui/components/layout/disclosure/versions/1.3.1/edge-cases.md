
- In controlled mode the component never writes internal state — the caller owns `open`.
- `actions` are rendered outside the toggle `<button>`, so a click there cannot bubble into a toggle.
- Title and subtitle both truncate to keep the header a single row.
- Because children unmount when collapsed (**mount-children-only-when-open**), any uncommitted state inside them — e.g. a half-filled form — is discarded when the section closes, and they start fresh when it reopens.


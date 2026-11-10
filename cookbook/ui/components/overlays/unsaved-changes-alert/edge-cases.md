
- **Empty description**: When `description=""` is passed explicitly, the JS default parameter does not apply (defaults apply only to `undefined`), so the empty string is forwarded to AlertModal unchanged. Because the value is non-`null`, AlertModal still renders the description region and associates `aria-describedby` with it — the modal does NOT fall back to the default text. See unsaved-016.
- **Null or undefined description**: When `description` is not provided or is `undefined`, the component MUST use the default description "Your unsaved changes will be lost."
- **Very long description**: When `description` exceeds the modal's content width, the text SHOULD wrap within the modal body without breaking layout. See unsaved-018.
- **Required callbacks**: `onDiscard` and `onStay` are required props (see Configuration), not optional — the component defines no no-op or undefined-callback handling because the type system does not allow either to be omitted. See unsaved-019.
- **Rapid re-opens**: When the modal is closed (`open={false}`) and immediately re-opened (`open={true}`), the modal MUST display correctly with focus reset to the "Stay" button (per discard-requires-explicit-action). See unsaved-015.
- **Open toggle during interaction**: When the `open` prop is externally set to `false` while the modal is displayed, the modal MUST close, and that transition alone MUST NOT invoke `onDiscard` or `onStay` — the component holds no internal state and does not react to its own prop changes by firing callbacks. See unsaved-017.


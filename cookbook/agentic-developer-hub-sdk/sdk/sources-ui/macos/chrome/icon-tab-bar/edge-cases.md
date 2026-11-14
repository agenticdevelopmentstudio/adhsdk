
- **Empty item list (MUST)**: The component creates a control with no segments; `selectedID` always draws no selection and no click can occur.
- **Duplicate item ids (SHOULD NOT)**: Selection resolves to the first item with a matching id; the later duplicate can be clicked and reports its own id but is never drawn selected through `selectedID`.
- **Unknown or nil `selectedID` (MUST)**: No segment is selected, never an error.
- **Refused pick (MUST)**: A click the caller does not echo back through `selectedID` is undone on screen at once, before `onSelect` runs.
- **Missing symbol (MUST)**: A segment with an unresolvable symbol is drawn blank but keeps its width, tooltip and clickability.
- **Unchanged `selectedID` (MUST)**: Re-setting the same value does nothing.
- **Concurrent access**: Not applicable: the type is main-actor isolated, so all access is serialised on the main thread.
- **Error states and offline**: Not applicable: the component has no network, file or other dependency that can fail; a palette is always supplied by the theme observer.
- **Palette colour not convertible to sRGB (MUST)**: The brightness test treats a window background that cannot be converted as bright (1), so the track takes the light appearance.
- **Items fixed at creation**: The item list is a constant of the instance; to change panels a caller builds a new bar.


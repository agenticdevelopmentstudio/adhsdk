
- **Empty children**: `<Bleed>{null}</Bleed>` renders the `div` with no content; see **accept-children** (bleed-009).
- **Null or undefined `className`**: excluded from the class list before joining; see **falsy-class-filter** (bleed-007).
- **Side values outside the typed union**: the component renders whatever string is passed with no validation; see **side-passthrough** (bleed-010).
- **Multiple class names in `className`**: a space-separated value (e.g. `"custom-one custom-two"`) is appended as-is, unmodified; see **accept-class-name-prop** (bleed-011).
- **React.Fragment as child**: `<Bleed><>Content</></Bleed>` is valid; the fragment's children render inside the `div`; see **accept-children** (bleed-012).
- **Missing clipping parent**: if Bleed is not rendered inside an ancestor with `overflow-x: clip` (e.g. `.lp-band`; see the `Band` ingredient, [adhsdk.ingredient.landing.flow.band](cookbook:e0b59d60-0a56-4bf4-85cb-fb0e58170f8e)), the overhang widens the document instead of appearing cropped. This is an environmental prerequisite that Bleed cannot detect or enforce on its own.


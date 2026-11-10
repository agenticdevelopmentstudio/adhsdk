
- **Semantic heading**: Title is rendered as an `<h2>` to establish document outline hierarchy.
- **Help button label**: `aria-label="About this section"` describes the button purpose for screen readers.
- **Popover keyboard**: The help trigger is activated by click, Enter, or Space. Opening, closing (Escape or an outside interaction), and returning focus to the trigger are the underlying Popover component's behavior — see accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)) and accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)).
- **Text content**: Eyebrow and title content are read as-is; no additional aria-labels required if text is meaningful.
- **Icon-only button**: Help button contains only an icon; `aria-label` is REQUIRED to provide accessible name.


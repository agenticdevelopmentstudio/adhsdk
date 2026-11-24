
- **Empty title string**: The component does not validate `title`; passing an empty string still renders an `<h2>`, which is present in the DOM but conveys no accessible name to screen reader users. Callers MUST supply non-empty `title` content — Section Header itself performs no such check.
- **Very long title**: Title renders without an explicit wrap constraint. Because the left section has no flex-shrink override while the right section is `shrink-0`, the left section shrinks first as available width tightens, so a long title wraps onto multiple lines once space is insufficient.
- **Very long help content**: The popover has a fixed width (288px) and no max-height constraint in the source, so the panel grows to fit the content rather than scrolling.
- **Help button focus during popover open**: Escape closes the popover and returns focus to the trigger (accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)), accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))).
- **Multiple rapid help button activations**: The Popover trigger toggles open/closed state on activation, reflected via `aria-expanded` (accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))).
- **Actions slot too wide**: Actions element shares right section with help button; if actions exceed available space, layout depends on actions' own flex properties. The right section container applies `shrink-0`, so it does not shrink to accommodate overflow.
- **Custom className conflicts**: If `className` prop contains flex or positioning classes, they merge via `cn()` utility; later classes may override defaults (standard Tailwind precedence).


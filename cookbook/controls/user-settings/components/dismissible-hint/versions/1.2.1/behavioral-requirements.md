
- **accept-id-prop**: Component MUST accept a required string `id` prop that uniquely identifies this hint instance.
- **render-children**: Component MUST render the `children` prop as the hint's text content.
- **render-close-button**: Component MUST render a close button that, when clicked, dismisses the hint and persists the dismissal state.
- **render-close-glyph**: Component MUST render the close button with the literal text content "×".
- **persist-dismissal-state**: Component MUST persist dismissal state to browser localStorage with the key `{{app_prefix}}-hint-dismissed:<id>` set to the value `1`.
- **load-dismissal-state-on-mount**: Component MUST load dismissal state from localStorage on mount using the hint's `id` and set initial visibility accordingly.
- **not-render-when-dismissed**: Component MUST render as `null` if the dismissal state in localStorage indicates the hint has been previously dismissed.
- **handle-missing-localstorage**: Component MUST silently treat any localStorage read or write error as a failure and continue without throwing. On read error, the component MUST treat the hint as not dismissed (render normally). On write error, the component MUST still update its in-memory dismissed state to hidden for the current render, even though the value did not persist.
- **accept-classname-prop**: Component MUST accept an optional `className` prop and apply it to the container element, merged with the base class `{{app_prefix}}-hint`.
- **apply-note-role**: Component MUST render the container with `role="note"` for semantic accessibility.
- **label-close-button**: Component MUST render the close button with `aria-label="Dismiss"`.


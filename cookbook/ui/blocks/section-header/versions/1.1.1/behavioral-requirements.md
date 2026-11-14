
"Empty," for the `eyebrow`, `help`, and `actions` props below, means any JavaScript falsy value — `undefined`, `null`, `false`, or the empty string `""` — since each slot is guarded by a truthy check (`{prop && ...}`) in the source. This definition is also used by the Configuration table below.

- **render-title**: The component MUST render the `title` prop content as an h2 heading.
- **support-eyebrow**: The component MUST render the `eyebrow` prop when it is provided and non-empty; when `eyebrow` is empty, the eyebrow slot MUST NOT be rendered.
- **support-help**: The component MUST render a help trigger button when the `help` prop is provided and non-empty; when `help` is empty, the help trigger button MUST NOT be rendered.
- **support-actions**: The component MUST render the `actions` prop content when it is provided and non-empty; when `actions` is empty, the actions slot MUST NOT be rendered.
- **apply-custom-class**: The component MUST apply the `className` prop to the root container if provided.
- **display-help-popover**: When the help trigger button is activated — by click, or by keyboard Enter or Space while focused — the component MUST display a popover containing the `help` prop content, positioned below and aligned to the end (right edge). See accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)) and accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)) for how the popover closes and returns focus, and accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)) for its open/closed toggle state.
- **label-help-trigger**: The help trigger button MUST have an accessible label "About this section" via the `aria-label` attribute.
- **maintain-layout-order**: Left section (title area) MUST be positioned before right section (actions and help) in visual and DOM order.


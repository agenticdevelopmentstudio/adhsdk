
- **titled-header**: The component MUST render a header row containing the `title`, preceded by `icon` when provided and immediately followed by `titleAfter` when provided.
- **count-when-positive**: The component MUST render the `count` after the title only when it is provided and greater than zero, and MUST hide it otherwise.
- **header-slot-placement**: The component MUST place `center` in a centered, flexible header slot and `actions` in a right-justified header slot.
- **actions-right-justified-without-center**: When `actions` is present and `center` is absent, the component MUST push the actions to the right edge of the header.
- **shared-header-height**: The component MUST give the header a minimum height equal to `INFO_PANEL_HEADER_HEIGHT` so sibling panels' headers align.
- **content-sized-by-default**: By default (`scroll` false) the component MUST size the panel to its content and MUST NOT scroll the body.
- **fill-and-scroll-on-scroll**: When `scroll` is true, the component MUST let the panel flex to fill its track and MUST make the body scroll vertically when its content overflows.
- **body-ref-exposure**: The component MUST attach `bodyRef` to the scrolling body element so the host can tail or anchor it.
- **label-region**: The component MUST expose the panel as a labeled region whenever an accessible name can be computed — `ariaLabel` when provided, else `title` when it is a string. It leaves the region unnamed only when `title` is a non-string node and no `ariaLabel` is given (see Edge Cases, "Non-string title").
- **mode-default-padding**: The component MUST apply body padding defaulting by mode (card vs scroll) and MUST use `bodyPadding` when provided.
- **layout-prop-passthrough**: The component MUST apply caller-supplied `flex` and `maxHeight` to the outer element for host-controlled sizing.
- **host-attribute-passthrough**: The component MUST spread remaining host attributes (`data-*`, `id`, event handlers) onto the outer `<section>`, without overriding the computed accessible name: an explicit `ariaLabel` prop takes precedence over a raw `aria-label` present in the spread attributes, which in turn takes precedence over the string `title` fallback.


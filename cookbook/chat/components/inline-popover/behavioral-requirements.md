
- **render-toggle-button**: Component MUST render a clickable button element with aria-label="Toggle details".
- **toggle-visibility-on-click**: Component MUST toggle the open state when the toggle button is clicked.
- **initialize-with-default-open**: Component MUST initialize with the open state set to the value of the `defaultOpen` prop, which defaults to `true`.
- **render-title-when-provided**: Component MUST render the title text from `data.title` only if the property is truthy.
- **render-arrow-indicator**: Component MUST render an arrow span element as a visual indicator within the toggle button.
- **render-description-when-provided**: Component MUST render the description from `data.description` only if the property is truthy.
- **render-links-collection**: Component MUST render the links collection from `data.links` only if the property is truthy and has length greater than 0.
- **render-each-link-with-label**: Component MUST render each link with either its `label` property or fall back to its `url` property as the displayed text.
- **open-links-in-new-tab**: Component MUST open links in a new browser tab by setting `target="_blank"` and `rel="noopener noreferrer"` on each link element.
- **set-aria-hidden-attribute**: Component MUST set `aria-hidden="true"` on the root element when open state is `false` and `aria-hidden="false"` when open state is `true`.
- **add-open-class-when-open**: Component MUST add the CSS class `pc-popover-open` to the root element when the open state is `true`.


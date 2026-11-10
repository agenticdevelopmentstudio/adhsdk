
- **top-hairline**: Component MUST render a hairline separator at its top edge using the border theme role.
- **status-text-leading**: Component MUST display the status string at the leading edge of the bar.
- **middle-truncation**: Component MUST truncate status text by the middle when it exceeds available width.
- **hover-tooltip**: Component MUST display the full status text as a tooltip on pointer-capable platforms when not empty; when status is empty, tooltip MUST be cleared. On touch-only platforms, the full text remains available via the accessible label instead (see **full-text-accessible-label**).
- **full-text-accessible-label**: Component MUST expose the complete, untruncated status string as the status label's accessibility value, independent of visual truncation.
- **fixed-height**: Component MUST maintain a fixed height of 22pt.
- **status-vertical-centering**: Component MUST center-align the status label vertically within the bar.
- **trailing-accessories**: Component MUST accept an ordered list of accessory views for the trailing slot and render them in that order.
- **trailing-vertical-centering**: Component MUST center-align trailing accessory views vertically within the bar.
- **trailing-spacing**: Component MUST apply 6pt spacing between trailing accessory views.
- **edge-margins**: Component MUST maintain 10pt leading and trailing margins from the bar edges.
- **minimum-gap**: Component MUST maintain at least 8pt minimum gap between status label and trailing accessories when both are present.
- **theme-support**: Component MUST apply theme-aware colors: elevated surface background, border-role hairline, and secondary text.
- **accessibility-prefix**: Component MUST require an accessibility prefix string during initialization.
- **status-accessibility-id**: Component MUST assign an accessibility identifier to the status label using the provided prefix (formatted as `{prefix}.status`).


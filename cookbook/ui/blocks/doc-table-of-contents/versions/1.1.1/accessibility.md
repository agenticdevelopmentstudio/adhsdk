
- **Role**: The component renders as an `<aside>` (supplementary content region). The heading list renders as an unordered list (`<ul>`) with anchor links (`<a href="#id">`).
- **Label requirements**: The component's title (rendered as an `<h4>`) serves as the region label. Heading links MUST have accessible text derived from the heading content (the `heading.text` property).
- **Keyboard navigation**: All heading links MUST be keyboard-accessible via Tab and Enter (standard anchor link behavior). Focus indicators are browser-supplied.
- **Announce state changes**: Screen readers will announce heading links as navigational anchors. The active heading's increased font weight and color are visual affordances; the actual "current page location" is conveyed by the user's scroll position and the anchor link target.
- **Minimum tap target**: Heading links SHOULD meet a minimum touch target of 44×44 pt. This implementation's row height (0.125 rem vertical padding plus 14px text) is smaller than that; this is a layout constraint inherited from the document's fixed-width rail design, accepted here for inline text links within a document body (see **Compliance**).


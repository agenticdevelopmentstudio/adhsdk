
- **preserve-text-semantic-structure**: Component MUST preserve markdown semantic structure (headings, lists, emphasis) in the rendered output so assistive technologies can interpret document hierarchy.
- **map-alerts-to-color-and-label**: Alert blockquotes MUST be visually distinguished by both color (semantic role) and text label (NOTE, TIP, IMPORTANT, WARNING, CAUTION in uppercase; see **replace-alert-tag-with-label**). Color alone MUST NOT be the only distinguishing factor.
- **render-checkboxes-as-text**: Task list checkboxes MUST render as Unicode text characters (☐, ☑) so assistive technologies can announce them as text, not as interactive controls (task list items are not interactive in a static document).



- **Semantic element**: Component MUST use the `<p>` element to maintain semantic meaning for screen readers and document structure.
- **Content accessibility**: Text content rendered as children inherits the color and typography defined by the `.aws-explanation` rule in `styles.css`, which sets its text color from the `--aws-text-muted` design token. Whether the resolved token value meets WCAG 2.1 AA contrast has not been checked — see **Compliance**.
- **Label inheritance**: The paragraph element does not require an explicit label; the rendered text content serves as the semantic label.


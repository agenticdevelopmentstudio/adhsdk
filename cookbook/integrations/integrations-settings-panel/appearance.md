
- **Corner radius**: Not applicable: the panel draws no shape of its own; it composes the shared settings split view, list and footer.
- **Padding**: Not applicable: the panel sets no insets; spacing comes from the shared split view and footer, and the Gmail view owns its own padding.
- **Font**: Not applicable: the panel sets no fonts; the sidebar and detail use the shared settings styling.
- **Background**: Not applicable: no color is set in the panel; the detail body is wrapped in the themed root.
- **Foreground/Text**: Sidebar title "Integrations"; row label "Gmail".
- **Border**: A separator is drawn above the footer (`separatorAbove: true`).
- **Shadow**: Not applicable: the panel sets no shadow.
- **Min/Max size**: Not applicable: the panel sets no size constraints; the split view's divider and sizing are the shared base class's.
- **Icons**: The panel uses the `puzzlepiece.extension` system symbol; the Gmail row uses `envelope`. Neither carries an accessibility description.
- **Footer**: A `+` add button and a `−` remove button under the sidebar list. Their glyphs, sizes and spacing belong to the shared add-and-remove footer.


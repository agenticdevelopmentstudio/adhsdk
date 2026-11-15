
- **Corner radius**: The system segmented control's own.
- **Padding**: The control sits in the privacy toolbar row with that
  row's existing item spacing.
- **Font**: Not applicable for the control (icons only). The source view
  uses the theme's monospaced text font.
- **Background**: The preview draws its own fixed builder stylesheet
  (Design Decisions) on the theme's window background; the source view
  fills with the theme's text background.
- **Foreground/Text**: Source highlighting uses four theme roles: tags,
  attribute names, attribute values, and plain text.
- **Border**: Not applicable — neither view draws a border of its own.
- **Shadow**: Not applicable.
- **Min/Max size**: Both views fill the tab's content area exactly as the
  live page does.

Icons: `globe` (Website), `eye` (Agent preview),
`chevron.left.forwardslash.chevron.right` (Agent source).


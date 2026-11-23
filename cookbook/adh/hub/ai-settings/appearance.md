
- **Corner radius**: The models table sits in a rounded container with a one-pixel border in the
  border token; capability chips are small rounded rectangles.
- **Padding**: Table cells are 12px by 8px; chips are 4px by 2px; the editor's body is 24px by 16px with
  16px between groups; the pane title row is 24px by 16px at the top and 8px at the bottom.
- **Font**: Table body text is the small body size; header cells are monospace at 0.7rem, uppercase,
  letter-spaced, medium weight; numeric and family cells are monospace at the extra-small size; chips
  are monospace at 0.6rem.
- **Background**: The table header row uses the second surface token at 40 percent; chips use the
  second surface token.
- **Foreground/Text**: Model names use the primary text token; family, numbers and header cells the
  muted token; the empty-caps dash the dim token; "Connected successfully." the green token.
- **Border**: One pixel in the border token around the table container, under the header row and between
  body rows; informational template cards have the same border.
- **Shadow**: None.
- **Min/Max size**: None; the pane scrolls vertically and the table fills its group's width.

All values are design tokens and utility classes in source; the component defines no literal colors.


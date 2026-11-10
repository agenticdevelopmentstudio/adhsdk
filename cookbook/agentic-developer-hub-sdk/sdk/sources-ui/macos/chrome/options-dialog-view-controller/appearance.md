
- **Corner radius**: Rounded corners applied via the `NSButton` bezel style (`.rounded`) on the Done button; dialog background is system-defined.
- **Padding (stack insets)**: Top 18pt, left 20pt, right 20pt applied to the row/heading stack; the stack's own bottom inset is 8pt, which is internal spacing consumed before the explicit 12pt gap to the Done button described below — it is not the dialog's outer bottom margin.
- **Padding (Done button spacing)**: 12pt from the stack's bottom edge to the Done button's top, 16pt from the Done button's bottom to the dialog's outer bottom edge (the dialog's actual bottom margin), 20pt from the Done button to the right edge.
- **Row spacing**: 16pt vertical spacing between rows and between the heading and first row.
- **Font**: The heading uses `ThemedLabel` with `role: .secondaryText` and `textRole: .button`; rows use caller-provided styling.
- **Background**: `ThemedBackgroundView` with `role: .windowBackground` for the dialog container; Done button uses default system button styling.
- **Foreground/Text**: Heading text color determined by the `secondaryText` role of `ThemedLabel`.
- **Border**: None on the dialog; system button styling on Done button.
- **Shadow**: None visible; system window/sheet presentation may add shadow depending on context.
- **Min/Max size**: Minimum width is 340pt by default (customizable via `width` parameter); width grows if rows require more space. Minimum height is determined by the sum of heading, rows, spacing, and Done button.


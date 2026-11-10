
- **Font styling**:
  - Headers: title font (level 1, bold), heading font (level 2, bold), heading font (level 3), body font with bold (levels 4–6)
  - Body text: semantic body font
  - Code spans and code blocks: semantic code font (monospaced)
  - Table headers: semantic body font with bold
- **Colors**:
  - Primary text: supplied textColor parameter or theme primary text
  - Blockquote text: secondary text color
  - Code block background: controlBackground color
  - Link text: accent color with underline
  - Thematic break rule: divider color
- **Spacing**:
  - List indentation: one indent step per nesting level (e.g., `MarkdownBlockMetrics.indentStep`)
  - Blockquote indentation: one indent step per nesting level
  - Table columns: (Apple) a fixed number of evenly spaced tab stops (`MarkdownBlockMetrics.tableColumnCount`, `MarkdownBlockMetrics.tableColumnWidth` per column) applies to every table regardless of its actual column count — a table with more columns than the constant does not receive tab stops beyond it. (Web) column count and width come from each table's own `<td>`/`<th>` structure, styled by CSS, not a fixed constant.
  - Paragraph indentation: applied via `NSParagraphStyle` (headIndent, firstLineHeadIndent) or CSS margin/padding
  - Tab stops for list markers: one indent step beyond list indentation for text alignment
- **Min/Max size**: No intrinsic minimum or maximum; renders to the width of its container.


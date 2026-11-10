
- **Typography**: Follows Tailwind prose classes for consistent document rendering (headings, paragraphs, lists, tables, code blocks inherit prose styling).
- **Heading scroll offset**: A scroll margin is applied to all heading elements to account for fixed UI above when anchor links jump to headings.
- **Code block styling**: Pseudo-elements (`::before`, `::after`) removed from inline and block code to prevent stray glyphs.
- **Width constraint**: `max-w-none` allows the component to fill its container width; prose is not constrained to a specific column width.
- **Padding and margin**: Inherited from prose classes; no additional padding or margin applied by the component itself.


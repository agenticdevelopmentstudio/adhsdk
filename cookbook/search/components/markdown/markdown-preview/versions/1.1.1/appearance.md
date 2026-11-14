
- **Container**: Root `div` with class `adh-mv-content`, transparent background (content is rendered inside).
- **Reading palette**: Applied via inline `style` attribute with CSS custom properties from `READING_THEME.palette` (colors, spacing, typography defined by theme).
- **State container**: Nested `div` with class `adh-mv-state` or `adh-mv-state--error` (on error), centered or stacked layout.
- **State title**: `p` with class `adh-mv-state-title` (if shown).
- **State detail**: `p` with class `adh-mv-state-detail` (loading, empty, or error message text).
- **Retry button**: Built from `Button` component (variant: "outline", size: "sm"), placed below error detail with `className="mt-3"`.
- **Markdown body**: Rendered by `MarkdownRenderer` (no wrapper div or title; body only).



- **Empty title and null title**: Component defaults to "Untitled"; no visual distinction between the two.
- **Empty query string**: `splitHighlightSegments("text", "")` returns the full text with no marks; title and snippet render without highlights.
- **Null hit.category**: Category section is not rendered; layout does not reserve space for it.
- **Empty hit.tags array**: Tags section is not rendered; footer layout adapts.
- **Very long title**: Wraps onto multiple lines with no truncation (title is unclamped; the container grows to fit).
- **Very long snippet**: Clamped to 2 lines via CSS line-clamp (**limit-snippet-lines**); overflow is truncated with an ellipsis.
- **Very long author displayName or slug**: Author text may wrap within its footer area; no ellipsis applied (browser wraps).
- **Missing hit.author.displayName and hit.author.slug**: Component renders "@undefined" or similar; no error handling for missing author fields.
- **Very long category name**: Category capsule text may overflow; rendering depends on browser and container width (Tailwind's `whitespace-nowrap` is not applied to category, allowing wrap).
- **Future-dated hit.updatedAt**: `formatDate` is called as-is; output depends on the formatter's handling of future dates (no special case defined in component).
- **Roving tabindex with active = undefined**: This occurs only for standalone rendering outside list context — a list that manages roving tabindex always passes an explicit `active` boolean. The native tab order applies with no overriding tabindex logic.


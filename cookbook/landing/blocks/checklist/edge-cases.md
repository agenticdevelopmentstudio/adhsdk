
- **Empty groups array**: If the groups prop is an empty array, the component renders an empty div with class `lp-checklist`. No error occurs.
- **Null or undefined items array**: Not applicable: TypeScript interface requires `items: ChecklistItem[]` (non-nullable); items array is always present and is always an array.
- **Empty text**: An item with an empty string or empty ReactNode for `text` renders the list item and span; the span contains the empty text. No special handling or hiding occurs.
- **soon property edge cases**: `soon` is typed as an optional `boolean`, so it is either `true`, `false`, or absent; absent or `false` means not soon.
- **ReactNode content in heading and text**: Both `heading` and `text` accept ReactNode, permitting complex nested content (elements, fragments, conditionals). The component renders them as-is without validation or sanitization.


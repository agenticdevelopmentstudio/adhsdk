
- **Corner radius**: 0 (none; element is a list structure)
- **Padding**: 0 × 0 (no internal padding; gap-0.5 controls spacing between rows)
- **Font**: monospace font family, 11px size
- **Background**: transparent (inherited from parent)
- **Foreground/Text**: Labels use `--color-text-dim` CSS variable; values use `--color-text-secondary` CSS variable
- **Spacing**: 0.5 (4px) vertical gap between rows; 2 (8px) horizontal gap between label and value within a row; 3 (12px) horizontal gap between wrapped array items
- **Layout**: Each field is its own row — a flex container (`gap-2`) pairing one `<dt>` with its `<dd>`, right-aligned; rows stack vertically inside the outer flex column (`flex-col`, `items-end`, `gap-0.5`). Array values wrap inside their `<dd>` as a separate flex group with end justification.
- **Margin**: 24px (mb-6) below the component


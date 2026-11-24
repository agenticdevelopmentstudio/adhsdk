
- **Container**: Vertical stack, full width, rows separated by a 12pt gap; part of the shared field-label-column group.
- **Row layout**: Each row places a right-aligned caption in the shared label column beside its control (inline field layout), not above it.
- **Title input**: Text input; inherits the platform's default height, padding, border, and font.
- **Slug input**: Text input; font is monospace at roughly 0.8× the title input's font size.
- **Status message**: Text, roughly 0.75× the body font size, colored by tone (muted, success, or error), positioned beside the slug input with an ~8pt gap.
- **Gap between rows**: 12pt.

Reference implementation (`document-identity-field.tsx`): the container uses Tailwind's `gap-3` (12px); the slug input uses `text-[0.8rem]`; the status message uses `text-xs` (0.75rem) and an 8px (`gap-2`) offset from the slug input.


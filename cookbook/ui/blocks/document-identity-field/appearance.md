
- **Container**: Vertical stack, full width, rows separated by a 12pt gap; part of the shared field-label-column group.
- **Row layout**: Each row places a right-aligned caption in the shared label column beside its control (the inline layout of the `Field` component ([adhsdk.ingredient.ui.blocks.field](cookbook:0c199036-81c3-47c3-9e79-e4b8187ca69a))), not above it.
- **Title input**: Text input (the `Input` component ([adhsdk.ingredient.ui.components.inputs.input](cookbook:0f5b7167-b375-4f44-977b-566f720a453d))); inherits the platform's default height, padding, border, and font.
- **Slug input**: Text input; font is monospace at roughly 0.8× the title input's font size.
- **Status message**: Text, roughly 0.75× the body font size, colored by tone (muted, success, or error), positioned beside the slug input with an ~8pt gap.
- **Gap between rows**: 12pt.

Reference implementation (`document-identity-field.tsx`): the container uses Tailwind's `gap-3` (12px); the slug input uses `text-[0.8rem]`; the status message uses `text-xs` (0.75rem) and an 8px (`gap-2`) offset from the slug input.


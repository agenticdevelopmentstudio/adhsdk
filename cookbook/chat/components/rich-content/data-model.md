
- **ContentItem**: `LinkContent | ImageContent` — the discriminated union that `items` is built from; `type` is the discriminator.
- **LinkContent**: `{ type: 'link'; url: string; label?: string }`. `url` is required by the type (a missing or null value at runtime is handled per **missing-field-handling**); `label` is optional and falls back to `url` as the visible text (per **safe-link-text**).
- **ImageContent**: `{ type: 'image'; src: string; alt?: string }`. `src` is required by the type (a missing value at runtime is handled per **missing-field-handling**); `alt` is optional and falls back to an empty string (per **image-alt-text**).


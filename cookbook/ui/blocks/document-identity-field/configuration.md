
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | string | (required) | Current title value |
| `onTitleChange` | (title: string) => void | (required) | Callback fired when user edits title |
| `slug` | string | (required) | Current slug value |
| `onSlugChange` | (slug: string) => void | (required) | Callback fired when user edits slug |
| `slugify` | (title: string) => string | (required) | Function to derive slug from title on title changes |
| `verdict` | SlugVerdict | `{ status: "idle", reason: null }` | Availability status for current slug, with optional reason text |
| `titleLabel` | string | "Title" | Label text for title input |
| `slugLabel` | string | "Slug" | Label text for slug input |
| `disabled` | boolean | false | If true, both inputs are disabled |
| `className` | string | undefined | Additional CSS class applied to container element |

The `useSlugAvailability(slug, check?, opts?)` hook takes these arguments:

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `slug` | string | (required) | The slug to ask about |
| `check` | (slug: string) => Promise<{ available: boolean; reason?: string }> | undefined | The availability checker; without one the verdict stays idle |
| `opts.debounceMs` | number | 350 | Quiet time before the checker is called |
| `opts.subject` | string \| null | null | What the answer belongs to (for example a document id); part of the stale-answer stamp |

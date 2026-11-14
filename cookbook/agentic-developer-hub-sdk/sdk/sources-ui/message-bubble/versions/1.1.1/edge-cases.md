
- **Empty text**: Message with empty or nil text still renders the sender name, timestamp, avatar slot, and any rich content or failure reason (see **text-content-rendered**, vector bubble-022).
- **Missing timestamp**: Message with nil timestamp omits the timestamp line; bubble still renders text and other content (see **timestamp-display**, vector bubble-023).
- **Long text**: Text that exceeds maxWidth wraps and the bubble expands vertically; measurement ensures the bubble is never wider than maxWidth (see **size-to-content**).
- **Very short text**: Single character or emoji text renders at the bubble's own measured size — no separate minimum width is enforced; padding is applied normally when the theme is not flat.
- **Theme change during rendering**: On platforms with live theme repainting (Apple), the bubble repaints synchronously; caller is responsible for triggering repaints when theme changes.
- **Flat theme transition**: When a theme's fill alpha transitions from > 0.001 to ≤ 0.001 (or vice versa), padding and corner radius update; no animation.
- **Multiple delivery statuses**: The component handles one status per render; if a message transitions from composing to failed, it must be re-rendered with the new status (see vector bubble-026).
- **Rich content load delay**: See **rich-content-load-gating** — the Web implementation renders nothing until every image in the content array has finished loading; callers must handle the interval where the component is not yet mounted.
- **Avatar/sender mark**: See **avatar-slot-rendered** — the avatar div is always rendered but may be empty when the sender has no avatar; themes can style the empty case with `.pc-avatar:empty`.


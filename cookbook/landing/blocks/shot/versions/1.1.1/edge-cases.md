
- **Media is undefined (or the prop is omitted)**: Placeholder renders; this is the design's primary state until a capture exists. The check is `media === undefined`, not a general falsy/nullish check: passing `media={null}` or `media={false}` takes the `media` branch and renders nothing, leaving a bare title bar with no placeholder and no caption — a host that wants the placeholder must leave `media` undefined (e.g. `capture ?? undefined`, not `capture ?? null`).
- **Caption is empty string**: Placeholder still renders with an empty caption area.
- **PendingLabel is empty string or falsy**: See **falsy-pending-label-omitted**; no visible content renders and the placeholder shows only the caption, the same visible result as pendingLabel being omitted.
- **Title is empty string**: Renders with an empty title bar; frame still displays.
- **Media is a complex nested component tree**: Rendered as-is without interaction or state management by Shot.
- **Media is a video element without preload/autoplay attributes**: Shot does not apply Reduce Motion behavior; host or a wrapper component (e.g., Clip from the same package) must handle motion preferences.


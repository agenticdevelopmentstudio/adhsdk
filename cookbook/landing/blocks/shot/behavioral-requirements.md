
- **frame-chrome**: Component MUST render a macOS-style window frame: a title bar with three decorative dots (styled after macOS traffic lights, uniformly colored) and a window title.
- **title-in-bar**: Component MUST display the `title` prop text in the frame's title bar.
- **media-verbatim**: When `media` is provided, component MUST render it exactly as passed, with no transformation, processing, or motion handling.
- **placeholder-when-no-media**: When `media` prop is absent, component MUST render an obviously unfinished placeholder frame.
- **caption-in-placeholder**: Component MUST render the `caption` prop as text content in the placeholder.
- **pending-label-above-caption**: When `pendingLabel` is provided, component MUST render it above the caption in the placeholder; when omitted, the placeholder displays only the caption.
- **falsy-pending-label-omitted**: When `pendingLabel` is a falsy `ReactNode` (`""`, `false`, `null`), it MUST NOT render visible content — the same visible result as when it is omitted.
- **pending-label-verbatim**: Component MUST render `pendingLabel` exactly as passed without transformation.


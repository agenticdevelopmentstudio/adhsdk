
The component contains no user-facing text of its own; the native video controls (when visible) are localized by the browser using the OS locale. The `label` prop is passed straight through to the video element's `aria-label` without any transformation — the caller MUST pass an already-localized `label` string; the component does not translate, format, or otherwise process it.


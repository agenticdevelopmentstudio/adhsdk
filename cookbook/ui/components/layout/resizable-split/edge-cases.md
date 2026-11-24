
- **localStorage access failure (SSR, sandboxed iframes, disabled storage)**: Wrapped in try-catch; on any error the component silently falls back to `defaultRatio` or the in-memory ratio.
- **Restored value outside bounds**: A persisted `localStorage` value outside `[minRatio, maxRatio]` (e.g. after the bounds changed since it was saved) is clamped to the current bounds on restore, the same as any other ratio update.
- **Zero-height container or content**: `revealRatioForContent()` guards against `containerH <= 0` or `contentH <= 0` by returning the fallback ratio; prevents NaN.
- **Concurrent collapse requests**: When controlled via the `collapsed` prop, rapid toggles are handled by React state; uncontrolled (internal) state updates synchronously per toggle, with no queue.
- **Drag-over-chevron suppression**: See `#requirements/chevron-toggle-suppressed-by-drag`.
- **Animation timer cleanup**: The animation timer is cleared on unmount to prevent dangling timeouts.


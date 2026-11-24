
- **Decision**: The component exposes four independent boolean behaviors (`openAtTop`, `armSnapping`, `armSmooth`, `restoreZoomOffIos`) rather than a single on/off switch.
  **Rationale**: Each behavior addresses a distinct UX concern (pull-to-refresh parity, preventing mid-load snap, respecting history traversal, accessibility), and disabling one does not require disabling the others.
  **Approved**: pending

- **Decision**: `armSnapping` and `armSmooth` arm on the reader's first input, not on page load or after a fixed delay.
  **Rationale**: Avoids the "mid-load snap" problem — if scroll snap were active during the initial layout pass while section heights are still settling, the snap engine would pick a snap point at an intermediate height, stranding the reader between two screens. Arming on first input guarantees the page is at rest when the property activates.
  **Approved**: pending

- **Decision**: `armSmooth`'s `pointerdown`/`wheel`/`keydown` listeners intentionally omit `{once:true}` (unlike `armSnapping`'s, which use it), and a `popstate` listener clears `data-smooth` on every history traversal.
  **Rationale**: The browser's own scroll restoration uses `scroll-behavior: smooth` (from `base.css`), which would animate the reader back to a previous offset and create a false impression of travel. Clearing `data-smooth` on `popstate` removes easing from the restoration scroll; because the input listeners were never `{once:true}`, the very next input re-arms it before there is anything left to ease.
  **Approved**: pending

- **Decision**: `maximum-scale` is stripped from the viewport meta tag on every platform except iOS/iPadOS.
  **Rationale**: `maximum-scale=1` is the only way to stop iOS Safari zooming the page when a form field takes focus, so it ships in the meta tag for iOS; but it also disables pinch-zoom entirely, which is a real accessibility cost. On iOS the trade is made deliberately — pinch-zoom is knowingly sacrificed to prevent zoom-on-focus. Off iOS, where that hazard doesn't exist, stripping the constraint restores pinch-zoom with no downside.
  **Approved**: pending

- **Decision**: DeckScript renders a literal `<script>` tag with an inline body; it is not a React effect.
  **Rationale**: By the time React effects fire (after hydration), scroll restoration and user input may already have occurred. The script must run before any React lifecycle to have any of its four effects.
  **Approved**: pending

- **Decision**: The component SHOULD be rendered first inside `<body>`, not in `<head>`.
  **Rationale**: `restoreZoomOffIos` calls `document.querySelector('meta[name=viewport]')` immediately when the script runs. In `<head>`, the viewport meta tag may not yet be parsed, depending on framework render order. Placing the script first inside `<body>` guarantees the meta tag is already behind it in the DOM; the `load`-event fallback still catches a miss, but only from that point on, during which window non-iOS pinch-zoom stays disabled for nothing.
  **Approved**: pending


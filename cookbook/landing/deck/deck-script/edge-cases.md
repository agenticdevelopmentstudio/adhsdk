
- **Empty options object**: When `deckScript({})` is called, all four defaults (true) MUST be applied, returning the full script string.
- **Undefined options parameter**: When `deckScript()` is called with no arguments, defaults MUST be applied identically to `deckScript({})`.
- **Disabled all behaviors**: When `deckScript({ openAtTop: false, armSnapping: false, armSmooth: false, restoreZoomOffIos: false })` is called, the function MUST return an empty string.
- **Viewport meta tag missing**: When `restoreZoomOffIos` runs and no viewport meta tag exists yet, the code does not throw — the `if(m)` check short-circuits — and it awaits the `load` event to retry the query.
- **Multiple DeckScript renders**: Only one `<DeckScript />` instance SHOULD be rendered per page. Rendering more than one injects a separate script block per instance; the effects layer harmlessly (idempotent attribute sets, duplicate listeners) but wastes bytes and events.
- **DeckScript rendered in `<head>`**: The component SHOULD be placed first in `<body>` as documented; if placed in `<head>`, the viewport meta tag may not yet be parsed and `restoreZoomOffIos` behavior is degraded to only the `load` event fallback.
- **Input firing before arm-snapping's listeners attach**: A user CAN scroll, click, or press a key before this script reaches its listener-attachment lines — for example during a slow fetch of the surrounding HTML. That input is simply missed, since no listener exists yet to see it, and `data-snap` stays unset. The next `pointerdown`, `wheel`, or `keydown` after the script runs arms snapping normally.


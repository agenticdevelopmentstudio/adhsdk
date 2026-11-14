
DeckScript is a React component that renders inline scripts executed before page hydration to initialize scroll behavior, scroll snapping, smooth scroll easing, and iOS/iPadOS viewport zoom constraints. All four behaviors are optional and default to enabled. The component exports both a function that returns the script as a string and a React component that renders it. It SHOULD be placed first inside `<body>`, not `<head>`, so the viewport meta tag has already been parsed when `restoreZoomOffIos` runs; a `load`-event fallback covers a miss, but only from that point on.


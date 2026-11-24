
- **render-children**: Component MUST render its children as direct descendants, in document order, with no wrapper element inserted around them.
- **compose-classname**: Component MUST accept an optional `className` prop. When provided, the rendered element's `class` attribute MUST contain both the internal `vp-composer` class and the provided `className`, space-separated; when omitted, only `vp-composer` MUST appear.
- **adjust-bottom-padding**: Component MUST set its bottom padding to `calc(var(--kb-inset) + env(safe-area-inset-bottom))` (implemented as `calc(var(--kb-inset) + var(--safe-bottom))`, with `--safe-bottom` resolving `env(safe-area-inset-bottom, 0px)`) so it lifts above the keyboard and respects the home indicator, animating the change over 180ms ease-out.
- **kb-inset-read-only**: Component MUST read the `--kb-inset` custom property but MUST NOT set it. The value is written by `useKeyboardInset()`, which the parent `ViewportShell` mounts; see [adhsdk.ingredient.viewport.viewport-shell](cookbook:960a1577-bf48-4d56-a93f-aa690853f64f) (the **keyboard-inset** requirement) — `useKeyboardInset` is not itself a separate recipe.


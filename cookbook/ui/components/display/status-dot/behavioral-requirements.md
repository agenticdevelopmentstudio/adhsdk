
- **derives-fill-from-currentcolor**: The component MUST fill the dot with `background: currentColor` so the tone class alone sets the fill color.
- **derives-glow-from-currentcolor**: The component MUST render a soft `box-shadow` glow whose color is a `color-mix` of the same `currentColor`, so one tone class drives both fill and glow.
- **tone-sets-currentcolor**: The component MUST map each `tone` to an `apt-*` text-color class (`neutral`→`text-apt-text-muted`, `muted`→`text-apt-text-dim`, `accent`→`text-apt-gold`, `blue`→`text-apt-blue`, `orange`→`text-apt-orange`, `success`→`text-apt-green`, `error`→`text-apt-red`). `neutral` is the one tone this component overrides from the shared family table.
- **defaults-to-neutral-tone**: With no `tone`, the component MUST use the `neutral` tone (`text-apt-text-muted`).
- **sizes-in-px**: The component MUST render the dot at `size` px square (default `10`) via inline `width`/`height`.
- **scales-glow-with-size**: The component MUST set the glow radius to `max(6, round(size * 0.55))` px so the glow grows with the dot but never falls below 6 px.
- **labeled-is-accessible-image**: Given a `label`, the component MUST expose `role="img"` and `aria-label` set to that label.
- **unlabeled-is-decorative**: With no `label`, the component MUST render `aria-hidden="true"` and no `role`, so it is skipped by assistive technology.
- **passes-label-through-verbatim**: The component MUST render a provided `label` verbatim as `aria-label`, without concatenating, translating, or otherwise transforming it (the consumer's duty to supply a localized string is in Localization).
- **merges-classname**: The component MUST merge any `className` after the tone class via `cn()`, so a consumer MAY add layout classes without losing the tone.
- **memoizes-render**: Since every prop is a primitive, the component SHOULD be wrapped in a memoization boundary (`React.memo`) so an unchanged dot skips re-render on a frequently-updating parent.


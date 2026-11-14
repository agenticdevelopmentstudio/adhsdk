
Text Lens (`@adh-sdk/textlens`) is a headless, framework-light
effect that sweeps a soft focal point back and forth along a line of text.
Each character the lens passes over swells, blurs and tints toward an accent
colour, then settles back as the lens moves on. It has three cooperating
pieces:

- **`color.ts`** parses a hex or `rgb()`/`rgba()` colour string into three
  numeric channels (`parseColor`) and resolves a lens colour — literal or a
  CSS custom property name — against a live element's computed style
  (`resolveColor`).
- **`lens.ts`** owns the effect itself. `createLens(elements, options)`
  destructively splits each target element's text into one `<span>` per
  character, then returns a `Lens` (`start`/`stop`/`destroy`) that drives a
  `requestAnimationFrame` loop writing `transform`, `filter` and `color`
  inline styles onto the character spans that fall within `radius` of the
  travelling centre.
- **`useTextLens.ts`** is the React binding: one `useEffect` that builds a
  lens over the elements matching `selector` inside a container ref, starts
  it (optionally after `startDelay`), and destroys it on cleanup or when
  `enabled` becomes `false`.

`createLens` has no dependency on React and no rendered surface of its own —
it mutates inline styles on elements the caller already rendered. A port to
another platform is translation work: the colour parsing, the per-frame
sweep math, and the lifecycle rules below apply identically wherever a host
can attach per-character views and drive a per-frame callback.


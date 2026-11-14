
A lens (influence radius `radius`, default 44px) travels the string; glyphs near
its centre bulge and soften:

```
The founder note text under the traveling lens
              ~~~( O )~~~
                  ^ glyphs here: scale↑, blur↑, color colorFrom→colorTo
   glyphs outside the radius: plain, untouched
```

- Nearness `t = smoothstep(1 − dist/radius)` drives all three effects together:
  `transform: scale(1 + t·maxScale)`, `filter: blur(t·maxBlur)` (dropped below
  ~0.03px), `color: color-mix(in oklab, colorFrom, colorTo t%)`.
- Only glyphs currently under the lens get `will-change` promoted; it is dropped
  as each glyph leaves the lens, so at most a handful are ever composited.
- Defaults are subtle by design: `maxScale 0.18`, `maxBlur 0.4px`, `radius 44px`,
  `msPerChar 48`, `minDuration 4500ms`, `pauseMs 0` (continuous loop). Colours
  default to `currentColor` on both ends (no colour shift unless overridden).
- No raw hex, no `!important`; colours come from the caller / `currentColor`.


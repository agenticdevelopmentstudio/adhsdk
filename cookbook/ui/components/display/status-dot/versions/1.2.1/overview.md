
The shared `StatusDot` in `@adh-sdk/ui` — the family's "live light": a small
round dot whose **fill and soft glow both derive from one tone class**. The tone
class sets `currentColor` (`text-apt-green`, `text-apt-red`, …); the fill is
`background: currentColor` and the glow is a `box-shadow` whose color is a
`color-mix` of that same `currentColor`, so a single class drives the entire
treatment and no per-tone shadow is hand-written.

It is sized in **px** (`size`, default `10`) rather than a scale step, because it
must optically align with mono text at many sizes — a status word beside it, a
row label, a hero figure. The glow radius scales with the dot
(`max(6, round(size * 0.55))` px) so a large dot still reads as a soft light
rather than a flat disc.

Accessibility is driven by `label`: pass the status word and the dot becomes an
accessible image (`role="img"` + `aria-label`); omit it — the common case, where
visible text already carries the meaning — and the dot is `aria-hidden`
decoration. A single export ships from
`@adh-sdk/ui/components/status-dot`: the `StatusDot` component. It is a pure
presentational span with no internal state and no `"use client"` directive.


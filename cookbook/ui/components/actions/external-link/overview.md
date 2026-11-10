
The shared `ExternalLink` in `@adh-sdk/ui` — the "{label} ↗" deep link out of
the app: an anchor that **always opens in a new tab** (`target="_blank"`) with
the safe `rel="noopener noreferrer"`, ending in a trailing ↗ arrow affordance.
Its default skin is the dashboard deep-link grammar — small, mono, info-blue,
`whitespace-nowrap` — the look used for "PostHog ↗" / "GlitchTip ↗" jump-outs to
external tools.

The component is deliberately thin: it spreads native anchor props
(`React.ComponentProps<"a">`), so `href`, `onClick`, `title`, `data-*` and the
rest pass straight through, and it merges an optional `className` via `cn()` for
restyling. Two consumption modes exist. **Default:** trailing glyph on, for a
standalone deep link. **`glyph={false}`:** drop the arrow when a *leading* icon
already carries the "external" meaning — UserCard's social links do this
(lucide `ExternalLink` icon + restyled to sans, muted text), and StatCard puts
the default-skin link in its header actions slot.

A single export ships from `@adh-sdk/ui/components/external-link`: the
`ExternalLink` component. It is a stateless anchor with no `"use client"`
directive.


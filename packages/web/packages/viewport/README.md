# `@adh-sdk/viewport`

Page-shell primitives that make iOS keyboard + viewport handling a solved
problem. Consumers compose three components and import one CSS file; the
package owns the platform-correctness, the consumer owns nothing.

## Why

`100vh`, `100dvh`, and `<meta interactive-widget=resizes-content>` do not
shrink the layout viewport when the iOS soft keyboard opens. The only API
that reflects keyboard height is `window.visualViewport`. This package
bundles:

- a hook that watches `visualViewport` and writes the keyboard height to
  the `--kb-inset` CSS variable on `:root`,
- CSS that locks `html, body` to the visible viewport (no rubber-band, no
  body scroll), and
- three layout components (`ViewportShell` / `ViewportSpacer` /
  `ViewportComposer`) that compose into a bottom-anchored page where the
  composer lifts above the keyboard.

## Usage

```tsx
import {
  ViewportShell,
  ViewportSpacer,
  ViewportComposer,
} from '@adh-sdk/viewport'
import '@adh-sdk/viewport/css/base.css'

export default function Page() {
  return (
    <ViewportShell className="max-w-3xl mx-auto px-4">
      <ViewportSpacer />
      <ViewportComposer>
        <YourChatOrFormHere />
      </ViewportComposer>
    </ViewportShell>
  )
}
```

The composer's bottom padding is
`calc(var(--kb-inset) + env(safe-area-inset-bottom))` — the keyboard
height plus the home-indicator safe area — and animates with a 180ms ease.

## API

### `<ViewportShell>` (client component)

Top-level page shell. Wraps children in a vertical flex container sized
to `100dvh`, and mounts `useKeyboardInset` so `--kb-inset` is live.

| Prop | Type | Notes |
|---|---|---|
| `className` | `string?` | Concatenated after `viewport-shell` for layout extras (max-width, padding, etc.) |
| `children` | `ReactNode` | |

### `<ViewportSpacer>`

Flex spacer (`flex: 1 1 0; min-height: 0`) that absorbs leftover vertical
space, pushing siblings to the bottom. Use as the first child of
`<ViewportShell>` when the composer should anchor to the bottom.

### `<ViewportComposer>`

Bottom-anchored slot. Its bottom padding tracks `--kb-inset` and the
safe-area inset so the contents lift above the iOS keyboard automatically.

### `useKeyboardInset()`

The hook `<ViewportShell>` mounts. Exported separately for advanced cases
where you want the `--kb-inset` variable without the shell layout.

## Required next/HTML setup

For Next 15:

```ts
// app/layout.tsx
import type { Viewport } from 'next'

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  viewportFit: 'cover',
  interactiveWidget: 'resizes-content', // Android only; iOS no-op
}
```

For other frameworks:

```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover, interactive-widget=resizes-content">
```

# `@adh-sdk/popover`

A hover popover: an anchored panel, the arrow that points back at whatever
opened it, the invisible bridge that lets the pointer cross the gap between
the two, and the one-open-at-a-time state a row of them needs.

## Why

Three things about a hover popover are fiddly enough to be worth owning
once:

- **The arrow.** It is a square rotated 45° sitting *behind* the panel, so
  the panel's own background hides its two inner edges and only the outer
  two carry a border. Painted any other way it is a diamond with a seam
  through it, and a skin that recolours the panel without recolouring the
  arrow leaves a mismatched triangle hanging off the corner. Here the arrow
  reads `--popover-surface` and `--popover-border` — the same properties the
  panel does — so it cannot drift.
- **The gap.** A panel offset from its trigger has dead space between them.
  Cross it and the pointer is over neither element. The package covers it
  with a transparent pseudo-element on the panel, so the panel is already
  under the pointer the moment it leaves the trigger.
- **Hover intent.** `onMouseLeave` → close is wrong: it shuts the panel
  under a hand that is still travelling toward it. Closing is deferred, and
  any re-entry cancels it.

The panel is **hidden, never unmounted**. Its contents are in the document —
and so in server-rendered HTML — whether or not anyone has a pointer.

## Usage

```tsx
import {
  Popover,
  PopoverAnchor,
  useHoverPopoverGroup,
} from '@adh-sdk/popover'
import '@adh-sdk/popover/css/base.css'

function Row({ items }: { items: Record<string, { title: string; body: string }> }) {
  const group = useHoverPopoverGroup()

  return (
    <div className="row">
      {Object.entries(items).map(([key, item]) => {
        const { anchorProps, triggerProps, popoverProps } = group.itemProps(key)
        return (
          <PopoverAnchor key={key} {...anchorProps}>
            <span {...triggerProps}>{item.title}</span>
            <Popover {...popoverProps}>{item.body}</Popover>
          </PopoverAnchor>
        )
      })}
    </div>
  )
}
```

Groups nest. A popover whose own contents are triggers calls
`useHoverPopoverGroup()` again for that inner row; the two groups do not see
each other. Reset the inner one when the outer panel closes:

```tsx
useEffect(() => {
  if (!open) inner.close()
}, [open, inner])
```

## Skinning

Override the custom properties; do not restate the rules. Everything is
declared on `.hover-popover` in `css/base.css`.

| Property | Default | |
|---|---|---|
| `--popover-width` | `408px` | |
| `--popover-gap` | `14px` | Trigger-to-panel distance; the arrow lives in it |
| `--popover-inset` | `16px` | Arrow's offset from the panel's leading edge |
| `--popover-arrow` | `16px` | Arrow square's side |
| `--popover-bridge` | `calc(var(--popover-gap) + 2px)` | Height of the transparent gap-spanning hit area |
| `--popover-surface` | `rgba(20, 20, 26, 0.94)` | Panel **and** arrow fill |
| `--popover-border` | `1px solid #2a2a36` | Panel **and** arrow stroke (a full `border` shorthand) |
| `--popover-radius` | `8px` | |
| `--popover-shadow` | `0 8px 32px rgba(0, 0, 0, 0.5)` | |
| `--popover-backdrop` | `blur(16px)` | |
| `--popover-lift` | `4px` | Distance the panel travels as it opens; `0` under `prefers-reduced-motion` |
| `--popover-duration` | `0.12s` | |
| `--popover-ease` | `cubic-bezier(0.16, 1, 0.3, 1)` | |

```css
.hover-popover {
  --popover-surface: var(--surface);
  --popover-border: 1px solid var(--border);
}
```

## API

### `<PopoverAnchor>`

The positioning context (`position: relative`) — nothing else. It wraps both
the trigger and the panel, which is what makes the close delay work: moving
from one to the other never leaves the anchor.

| Prop | Type | |
|---|---|---|
| `className` | `string?` | Concatenated after `hover-popover-anchor` |
| `onMouseLeave` | `() => void` | From `itemProps(key).anchorProps` |

### `<Popover>`

| Prop | Type | |
|---|---|---|
| `open` | `boolean` | |
| `placement` | `'top' \| 'bottom'` | Default `top`; also decides which way the arrow points |
| `className` | `string?` | Concatenated after the package's classes |
| `onMouseEnter` / `onMouseLeave` | `() => void` | From `itemProps(key).popoverProps` |

### `useHoverPopoverGroup(options?)`

At most one popover in the group is open.

| Option | Default | |
|---|---|---|
| `closeDelay` | `200` | ms between the pointer leaving an anchor and the panel closing |

Returns `{ openKey, close, itemProps }`. `openKey` is the open item's key or
`null` — useful for driving anything that should pause while a panel is up.
`itemProps(key)` returns `{ anchorProps, triggerProps, popoverProps }` to
spread onto the three elements.

## Keyboard and assistive technology

This is a pointer-driven component: the trigger is not focusable and there
is no keyboard path to open a panel. That is a real gap, deliberately not
papered over with `aria-hidden` — the panel's content stays exposed to
assistive technology and to crawlers at all times, which is the more useful
half of the trade while the interaction stays hover-only.

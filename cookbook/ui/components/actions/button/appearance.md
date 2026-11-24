
```
┌──────────────────┐        ┌──────────────────┐
│   Button         │   →    │   Button         │  (held: dipped 1px + darkened)
└──────────────────┘        └──────────────────┘
       idle                       data-pressed
```

- Base: `inline-flex` centered, `rounded-lg`, `text-sm font-medium`, `transition-all`,
  `select-none`; focus-visible ring via the `ring`/`border-ring` tokens.
- Variants: `default`, `outline`, `secondary`, `ghost`, `destructive`, `warning`,
  `destructive-ghost`, `link` — all expressed in shadcn theme tokens (the
  button's established vocabulary), never raw colors. `destructive-ghost` is a
  borderless destructive action, used by `ButtonBar` / `ListWithDetailsPane`.
  `warning` is one step down the status spectrum from `destructive`, for
  consequential-but-not-destructive actions (e.g. an ownership transfer). Each
  variant's resting tokens and the hover/active tokens layered on top of them:

  | Variant | Resting tokens | Hover / active tokens |
  |---|---|---|
  | `default` | `bg-primary text-primary-foreground` | `hover:bg-primary-bright` |
  | `outline` | `border-input bg-input/30` | `hover:bg-input/50 hover:text-foreground`, `aria-expanded:bg-muted aria-expanded:text-foreground` |
  | `secondary` | `bg-secondary text-secondary-foreground` | `hover:bg-secondary/80`, `aria-expanded:bg-secondary aria-expanded:text-secondary-foreground` |
  | `ghost` | (transparent) | `hover:bg-muted/50 hover:text-foreground`, `aria-expanded:bg-muted aria-expanded:text-foreground` |
  | `destructive` | `bg-destructive/15 text-destructive` | `hover:bg-destructive/25`, `focus-visible:border-destructive/40 focus-visible:ring-destructive/40` |
  | `warning` | `bg-apt-orange/15 text-apt-orange` | `hover:bg-apt-orange/25`, `focus-visible:border-apt-orange/40 focus-visible:ring-apt-orange/40` |
  | `destructive-ghost` | `text-destructive` | `hover:bg-destructive/10 hover:text-destructive`, `aria-expanded:bg-destructive/10 focus-visible:border-destructive/40 focus-visible:ring-destructive/40` |
  | `link` | `text-primary underline-offset-4` | `hover:underline` |

- Sizes: `xs`, `sm`, `default`, `lg`, plus `icon`/`icon-xs`/`icon-sm`/`icon-lg`,
  mapped to their height/width utility:

  | `size` | Utility | Rendered dimension |
  |---|---|---|
  | `xs` | `h-6` | 24px tall |
  | `sm` | `h-7` | 28px tall |
  | `default` | `h-8` | 32px tall |
  | `lg` | `h-9` | 36px tall |
  | `icon-xs` | `size-6` | 24×24px |
  | `icon-sm` | `size-7` | 28×28px |
  | `icon` | `size-8` | 32×32px |
  | `icon-lg` | `size-9` | 36×36px |
- Pressed: `data-[pressed]:not-aria-[haspopup]:translate-y-px` plus
  `data-[pressed]:not-aria-[haspopup]:brightness-95`.
- Min/Max size: `min-height: var(--adh-button-min-height, 0px)` and
  `min-width: var(--adh-button-min-width, 0px)` — both default to `0px`, so the
  button's rendered height/width comes solely from its `size` variant's fixed
  `h-*`/`size-*` utility unless an ancestor sets one or both variables. The
  `icon*` sizes redefine `--adh-button-min-width` to `var(--adh-button-min-height,0px)`
  rather than emitting a second `min-w-*` utility, because `buttonVariants` is
  also called bare (no `cn`/tailwind-merge pass) where two competing arbitrary
  `min-width` utilities would be resolved by unpredictable CSS source order.
- Icon SVGs: `pointer-events-none`, `shrink-0`; an SVG with no `size-*` class
  gets `size-4` (1rem) by default, `size-3.5` (0.875rem) at `sm`, `size-3`
  (0.75rem) at `xs`/`icon-xs`.
- No raw hex; no `!important`.


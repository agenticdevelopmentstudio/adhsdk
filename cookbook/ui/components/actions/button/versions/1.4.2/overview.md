
The shared `Button` in `@adh-sdk/ui` — a Base UI button primitive dressed in
the shadcn token vocabulary so every site drawing from `@adh-sdk/ui`
renders one button. It exposes eight visual `variant`s × a size scale, the standard disabled/focus/
invalid states, a **pointer-driven pressed state** that reflects a real press
the way CSS `:active` cannot, and an **ancestor-settable minimum touch-target
floor** that lets a surface raise every descendant button's minimum hit area
without changing any button's `size` prop.

Two exports ship from `@adh-sdk/ui/components/button`:

- `buttonVariants` — the `cva` styling function. It MUST stay callable from
  server components (e.g. `<Link className={buttonVariants()}/>`), so `button.tsx`
  carries no `"use client"` directive.
- `Button` — a thin wrapper that computes the variant classes (server-safe) and
  renders the `"use client"` interactivity layer `PressableButton`
  (`button-pressable.tsx`), which owns the pointer/press hooks.

The pressed visual (a small downward dip plus a subtle darken) is driven by the
`data-pressed` attribute that `PressableButton` toggles, not by `:active` — so the
press correctly clears when the pointer leaves the button while it is still held.


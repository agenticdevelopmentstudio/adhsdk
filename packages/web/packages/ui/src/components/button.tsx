import type { Button as ButtonPrimitive } from "@base-ui/react/button"
import { cva, type VariantProps } from "class-variance-authority"

import { cn } from "../lib/utils"
import { PressableButton } from "./button-pressable"

// The family Button — Base UI primitive + shadcn token vocabulary. Mirrors hub's
// component so the shared library and hub render identically.
//
// This module stays WITHOUT a "use client" directive (matches hub/shadcn) so
// `buttonVariants` stays a plain function callable from server components, e.g.
// `<Link className={buttonVariants()}/>`. The pointer-driven pressed state needs
// hooks, so it lives in the sibling `"use client"` <PressableButton>; <Button>
// here is a thin wrapper that computes the variant classes (server-safe) and
// renders that client interactivity layer — the same way it already renders the
// Base UI client primitive.
//
// Pressed feel: the dip + subtle darken react to `data-pressed` (set by the
// pointer tracking in <PressableButton>) instead of CSS `:active`, so the press
// correctly clears when the pointer leaves the button while held — which `:active`
// does not. The `not-aria-[haspopup]` exclusion (popup triggers don't dip) stays.
// The family theme is var-driven (light/dark resolve through the runtime M3 role
// vars), so no `dark:` forks here — they'd fire off the visitor's OS scheme and
// diverge from the active theme. Values below are the family treatments.
//
// A SURFACE CAN RAISE THE FLOOR without restyling a single button. `--adh-button-min-height`
// and `--adh-button-min-width` default to `0px`, so nothing changes anywhere until an
// ancestor sets them; a surface that wants a bigger hit target (shipr's dialogs, where the
// buttons were reported as too small) sets the pair once on itself and every descendant
// button grows — whatever its `size`, and including ones nested components render that the
// surface never names. The alternative was passing `size="lg"` down through every dialog,
// every button bar and every shared component between them, which is the same decision made
// in a hundred places and is why it drifted in the first place.
//
// The `icon*` sizes REDEFINE `--adh-button-min-width` on themselves, to the min-HEIGHT var: an
// icon button is square by definition, and a wider floor than tall would turn it into a lozenge.
// It redefines the variable rather than emitting a second `min-w-*` utility, because
// `buttonVariants` is also called bare (`<Link className={buttonVariants()}/>`) where no
// tailwind-merge runs to resolve the two — and which of two arbitrary `min-width` utilities wins
// there is decided by CSS source order, i.e. by nothing anyone can see from here.
const buttonVariants = cva(
  "group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 data-[pressed]:not-aria-[haspopup]:translate-y-px data-[pressed]:not-aria-[haspopup]:brightness-95 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive/50 aria-invalid:ring-3 aria-invalid:ring-destructive/40 min-h-[var(--adh-button-min-height,0px)] min-w-[var(--adh-button-min-width,0px)] [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary-bright",
        outline:
          "border-input bg-input/30 hover:bg-input/50 hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground",
        secondary:
          "bg-secondary text-secondary-foreground hover:bg-secondary/80 aria-expanded:bg-secondary aria-expanded:text-secondary-foreground",
        ghost:
          "hover:bg-muted/50 hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground",
        destructive:
          "bg-destructive/15 text-destructive hover:bg-destructive/25 focus-visible:border-destructive/40 focus-visible:ring-destructive/40",
        // The `destructive` treatment one step down the status spectrum, for a
        // consequential-but-not-destructive action: an ownership transfer moves an
        // object and drops other people's access, but destroys nothing. Reads the M3
        // `warning` role (exposed as apt-orange by @adh-sdk/themes)
        // rather than minting a second alias for it — every theme defines that role, so
        // this needs no new token and no per-theme work.
        warning:
          "bg-apt-orange/15 text-apt-orange hover:bg-apt-orange/25 focus-visible:border-apt-orange/40 focus-visible:ring-apt-orange/40",
        "destructive-ghost":
          "text-destructive hover:bg-destructive/10 hover:text-destructive aria-expanded:bg-destructive/10 focus-visible:border-destructive/40 focus-visible:ring-destructive/40",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default:
          "h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2",
        xs: "h-6 gap-1 rounded-[min(var(--radius-md),10px)] px-2 text-xs in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3",
        sm: "h-7 gap-1 rounded-[min(var(--radius-md),12px)] px-2.5 text-[0.8rem] in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5",
        lg: "h-9 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2",
        icon: "size-8 [--adh-button-min-width:var(--adh-button-min-height,0px)]",
        "icon-xs":
          "size-6 [--adh-button-min-width:var(--adh-button-min-height,0px)] rounded-[min(var(--radius-md),10px)] in-data-[slot=button-group]:rounded-lg [&_svg:not([class*='size-'])]:size-3",
        "icon-sm":
          "size-7 [--adh-button-min-width:var(--adh-button-min-height,0px)] rounded-[min(var(--radius-md),12px)] in-data-[slot=button-group]:rounded-lg",
        "icon-lg": "size-9 [--adh-button-min-width:var(--adh-button-min-height,0px)]",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

function Button({
  className,
  variant = "default",
  size = "default",
  ...props
}: ButtonPrimitive.Props & VariantProps<typeof buttonVariants>) {
  return (
    <PressableButton
      className={cn(buttonVariants({ variant, size, className }))}
      {...props}
    />
  )
}

export { Button, buttonVariants }

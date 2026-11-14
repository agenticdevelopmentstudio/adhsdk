
*Provenance: `press-on-pointerdown-inside` through `no-pointer-capture` below describe the
observable pointer-tracking behavior of `Button` as rendered — behavior that `Button` gets by
composing the sibling `PressableButton` (`button-pressable.tsx`), which is that contract's
single owner ([adhsdk.ingredient.ui.components.actions.button-pressable](cookbook:f483dfb7-d60e-4b12-8b17-2eb150b550db), see its own
`pressed-on-pointerdown` through `no-pointer-capture` requirements and its
**active press** terminology, called "held" below). This recipe restates them at the `Button`
level only so `Button`'s own Conformance Test Vectors can exercise them end-to-end; do not edit
them here without also checking `button-pressable.md`, and re-verify them here whenever that
recipe's requirements change, since `button.md`'s `depends-on` does not by itself trigger
re-extraction of this file.*

- **press-on-pointerdown-inside**: The button MUST set `data-pressed` when a pointer is pressed down inside it.
- **release-clears-pressed**: The button MUST clear `data-pressed` on `pointerup`.
- **cancel-clears-pressed**: The button MUST clear `data-pressed` on `pointercancel`.
- **leave-while-held-clears-pressed**: While the pointer is still held, the button MUST clear `data-pressed` when the pointer leaves it.
- **reenter-while-held-restores-pressed**: While the pointer is still held, the button MUST restore `data-pressed` if the pointer re-enters it.
- **release-outside-ends-hold**: The button MUST end the held state when the pointer is released or cancelled anywhere, including outside the button, so the press never sticks.
- **no-pointer-capture**: The button MUST track the press from held + pointer-inside state and MUST NOT call `setPointerCapture`.
- **pressed-visual-from-data-attr**: The button MUST express its pressed appearance (the translate-y dip plus darken) purely from `data-pressed`, never from CSS `:active`.
- **haspopup-suppresses-dip**: A button with `aria-haspopup` (a popup/menu trigger) MUST NOT apply the pressed dip.
- **keyboard-activates**: Space and Enter on a focused button MUST activate it (fire its click), independent of the pointer pressed visual.
- **forwards-consumer-pointer-handlers**: The button MUST still call any consumer-supplied pointer handler (e.g. `onPointerUp`) in addition to its own pressed tracking.
- **stable-public-api**: The button MUST keep its existing API — the `variant`/`size` props, the `buttonVariants` export, and `data-slot="button"` — unchanged.
- **supports-eight-variants**: The button MUST render one of exactly eight `variant` styles — `default`, `outline`, `secondary`, `ghost`, `destructive`, `warning`, `destructive-ghost`, `link`.
- **warning-variant-uses-warning-role**: The `warning` variant MUST render using the theme's `apt-orange` warning-role tokens (`bg-apt-orange/15 text-apt-orange`), visually distinct from the `destructive` variant's tokens.
- **defaults-to-default-variant-and-size**: The button MUST render the `default` variant at the `default` size when `variant`/`size` are not supplied.
- **respects-ancestor-min-height-var**: The button MUST apply `min-height: var(--adh-button-min-height, 0px)`, so an ancestor MAY raise the button's minimum height without the button changing its `size` prop.
- **respects-ancestor-min-width-var**: The button MUST apply `min-width: var(--adh-button-min-width, 0px)`, so an ancestor MAY raise the button's minimum width without the button changing its `size` prop.
- **icon-sizes-square-to-height-floor**: Each `icon`/`icon-xs`/`icon-sm`/`icon-lg` size MUST redefine `--adh-button-min-width` to the current `--adh-button-min-height` value, so an ancestor-raised height floor keeps an icon button square.
- **icon-svgs-non-interactive**: An SVG child of the button MUST NOT receive pointer events (`pointer-events: none`) and MUST NOT shrink in the flex layout (`flex-shrink: 0`).
- **unsized-icon-svgs-scale-with-button-size**: An SVG child that carries no `size-*` class MUST render at `1rem` (16px) square by default, `0.875rem` (14px) at the `sm` size, and `0.75rem` (12px) at the `xs`/`icon-xs` sizes.
- **consumer-classname-precedence**: The button SHOULD apply a consumer-supplied `className` so it can override the variant/size classes it conflicts with, per the project's `cn()` merge convention. (Rationale: see Design Decisions.)


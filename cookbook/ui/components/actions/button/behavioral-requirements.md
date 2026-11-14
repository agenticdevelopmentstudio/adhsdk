
*Provenance: `Button` gets its pointer-tracking behavior by composing the sibling `PressableButton` (`button-pressable.tsx`), which is that contract's single owner ([adhsdk.ingredient.ui.components.actions.button-pressable](cookbook:f483dfb7-d60e-4b12-8b17-2eb150b550db)). Its `pressed-on-pointerdown` through `no-pointer-capture` requirements and its **active press** terminology (called "held" in this ingredient's test vectors) apply to `Button` as rendered, and are not restated here. Test vectors T1-T6, T9, T10 and T23 exercise them end-to-end through `Button` and cite that ingredient's requirement names.*

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
- **disabled-never-pressed**: A `disabled` button MUST NOT set `data-pressed`; `disabled:pointer-events-none` means it receives no pointer events.
- **explicit-sized-svgs-untouched**: An SVG child that carries an explicit `size-*` class MUST keep that size; the default icon sizing rule MUST NOT override it (the rule is scoped with `:not([class*='size-'])`).
- **default-floor-is-zero**: When no ancestor sets `--adh-button-min-height` or `--adh-button-min-width`, both MUST resolve to `0px`, so the button is exactly as large as its `size` variant and no larger.

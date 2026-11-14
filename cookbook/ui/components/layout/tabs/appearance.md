
- **Corner radius**: 0 (no rounding)
- **Padding—Tabs root**: flex column with 20px gap (`gap-5`)
- **Padding—TabsList**: bottom padding 0, inline elements with 16px gap horizontally (`gap-4`)
- **Padding—TabsTab**: 8px vertical, 4px horizontal (`py-2 px-1`)
- **Font—TabsTab**: monospace, 0.8rem (12.8px), weight 400 (normal), tracking-wide (letter-spacing increased)
- **Background**: transparent (no fill)
- **Foreground—inactive**: muted gray text (`apt-text-muted`)
- **Foreground—active**: full contrast text (`apt-text`), gold underline (`apt-gold`)
- **Foreground—hover**: full contrast text (`apt-text`)
- **Foreground—disabled**: dimmed to 50% opacity with no hover response, keyed off `data-disabled`. The current source instead uses `disabled:pointer-events-none disabled:opacity-50`, which are Tailwind `:disabled`-pseudo-class selectors, and Base UI's `TabsTab` sets `aria-disabled`/`data-disabled` rather than the native `disabled` attribute (it is `focusableWhenDisabled`), so neither class matches: today a disabled tab keeps full opacity, still responds to hover, and remains keyboard-focusable, with only click-activation blocked (known non-conformance, see **Edge Cases**)
- **Border—TabsList**: 1px bottom border in neutral border color (`apt-border`)
- **Border—active tab**: 2px bottom border in gold (`apt-gold`), positioned at bottom of tab (negative margin `-mb-px` to overlap list border)
- **Shadow**: none
- **Min/Max size**: no size constraints on Tabs root; `TabsTab` renders at approximately 33px tall, assuming an inherited line-height of about 15px (the `text-[0.8rem]` size sets no line-height of its own, so it follows the surrounding context) + `py-2`'s 16px total vertical padding + `border-b-2`'s 2px


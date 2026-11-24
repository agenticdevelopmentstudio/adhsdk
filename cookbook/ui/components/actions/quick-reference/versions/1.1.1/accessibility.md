
- **Button role**: The trigger is a native `button` element with semantic button role.
- **Accessible name**: See #requirements (trigger-accessible-name). The trigger's `aria-label` MUST be non-empty and, when `triggerLabel` is present, MUST contain its text (WCAG 2.5.3 Label in Name).
- **Disclosure state**: See #requirements (trigger-disclosure-state). `aria-expanded` and `aria-haspopup` are set on the trigger by the Popover primitive, not by this component's own code.
- **Popover accessible name**: The popover panel itself sets no `aria-labelledby` linking it to the title text (the `<p>` element). Popover's own spec only recommends, but does not require, this association (`label-association`; see accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))), and this component does not add it. Screen readers get the panel's content without an explicit accessible name tied to the title.
- **Definition list structure**: Entries are marked up as `dl`, `dt`, and `dd` elements, providing semantic structure for assistive technology.
- **Focus management**: The popover is non-modal and does not contain focus while open; restoring focus to the trigger on dismiss is handled by the Popover primitive (see accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))), not reimplemented here.
- **Keyboard interaction**: Escape dismisses the popover (inherited from Popover; see accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))). Tab and Shift+Tab navigate within the popover while it is open.
- **Minimum touch target**: On web, the trigger MUST meet at least 24×24 CSS px (WCAG 2.5.8 Target Size Minimum) — the `sm` button size renders at 28px tall (`h-7`), which satisfies this. Native ports (iOS/Android) MUST meet the platform minimum (44×44pt / 48×48dp respectively).


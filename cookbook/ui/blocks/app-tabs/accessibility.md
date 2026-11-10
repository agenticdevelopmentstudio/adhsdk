
- **Role**: Tabs are rendered as `<button>` elements with `role="tab"`. The root container has `role="tablist"`.
- **State communication**: Active state is conveyed via the `aria-selected` attribute (`"true"` or `"false"`).
- **Label**: Each tab's label is rendered as visible text content within the button. No additional `aria-label` is present in source; labels are the visible text.
- **Icon handling**: Icons are rendered as visual content within the tab; they are not decorated with `aria-hidden` or labeled in source.
- **Keyboard interaction**: Handled by browser default button keyboard support (Tab to focus, Space/Enter to activate). No custom keyboard navigation (arrow keys, roving tabindex, or `aria-controls`) is implemented in source — this component uses `role="tablist"`/`role="tab"` for visual/semantic styling only, not the full WAI-ARIA APG tabs pattern (compare [adhsdk.ingredient.ui.components.layout.tabs](cookbook:fb3a0db4-691e-4025-a391-2853908248b5), which does implement that pattern via Base UI).
- **Minimum tap target**: `tabItemClass`'s padding (`py-2`, 8px vertical) yields a computed tab height of approximately 33px — below the 44×44pt (iOS) / 48×48dp (Android) platform touch-target minimums. This is a web-only CSS component; those native minimums are not applied by any shared class. Implementations on touch platforms SHOULD increase padding or add touch-specific sizing.


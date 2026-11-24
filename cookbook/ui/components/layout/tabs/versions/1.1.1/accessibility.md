
- **Role**: Component uses Base UI which applies `role="tablist"` to `TabsList`, `role="tab"` to each `TabsTab`, and `role="tabpanel"` to each `TabsPanel`.
- **Labels**: Tab buttons MUST contain visible text that describes the panel content (no aria-label unless text is insufficient).
- **Focus management**: Tab moves focus into the tablist as a single stop (landing on the active or last-focused tab, per the roving-tabindex pattern); Left/Right arrow keys then move focus between tabs, and Home/End move focus to the first/last tab — disabled tabs remain part of this focus order (`focusableWhenDisabled`) and are not skipped. This is Base UI's implementation of the WAI-ARIA APG Tabs pattern's roving-tabindex model, not standard sequential tab order. See **keyboard-tab-navigation**; RTL arrow-key reversal is documented under Localization.
- **State announcement**: Base UI applies `aria-selected="true"` to the active tab and `aria-selected="false"` to inactive tabs; screen readers announce selection state.
- **Disabled state**: Base UI applies `aria-disabled="true"` and a `data-disabled` attribute to a disabled `TabsTab`; it does not set the native `disabled` HTML attribute, so the tab stays in the keyboard focus order and only click-activation is blocked.
- **Minimum touch target**: Tab buttons MUST have a minimum height of 44px on touch platforms; current padding (`py-2`, 8px vertical) yields approximately 33px height; implementations on touch platforms SHOULD increase vertical padding or add touch-specific sizing.


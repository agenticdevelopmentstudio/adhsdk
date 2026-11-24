
- **render-tab-list**: Component MUST render a container for tab buttons with a bottom border line separating tabs from content.
- **render-tabs**: Component MUST render individual clickable tab buttons within the tab list.
- **render-panels**: Component MUST render content panels that display content associated with each tab.
- **default-value**: Component MUST accept a `defaultValue` prop to specify which tab is active on initial render (uncontrolled mode).
- **controlled-value**: Component MUST also support controlled selection via a `value` prop paired with `onValueChange`, so a parent can own the selection.
- **active-indicator**: Component MUST render a 2px accent-colored border at the bottom of the active tab to indicate selection state.
- **disabled-tabs**: Component MUST respect a `disabled` attribute on individual tabs to block click-activation, and a disabled tab MUST look dimmed (50% opacity, no hover response), styled through the `data-disabled` attribute; the tab remains keyboard-focusable. The current web source does not meet the visual half; see the known non-conformance in **Edge Cases**.
- **click-selection**: Component MUST change the active tab when a user clicks any non-disabled tab button.
- **keyboard-tab-navigation**: Component MUST support Left/Right arrow-key and Home/End navigation among tabs, and roving-tabindex Tab-key entry/exit into the tablist, per the WAI-ARIA APG Tabs pattern. In a right-to-left context the Left and Right arrows reverse (Left moves to the next tab, Right to the previous).
- **aria-tab-roles**: Component MUST expose `role="tablist"` on the tab container, `role="tab"` with `aria-selected` on each tab, and `role="tabpanel"` on each panel. Each tab MUST reference its panel's id with `aria-controls`, each panel MUST reference its tab's id with `aria-labelledby`, and a disabled tab MUST carry `aria-disabled="true"`.
- **visible-label**: Each tab MUST contain visible text that describes its panel's content; an `aria-label` is added only when that text is insufficient.
- **hover-emphasis**: Component tabs SHOULD change text color on hover to indicate interactivity (from muted to full contrast).
- **focus-visible-state**: Component tabs MUST show a visible keyboard-focus indicator that is distinct from the hover state (a ring or an underline). The web source shows it on keyboard focus only (`focus-visible:`): full-contrast text, a rounded corner and a 2px `apt-gold/40` ring, on top of `outline-none`; hover has no ring.
- **touch-target**: On touch platforms each tab SHOULD be at least 44px tall. The current web padding (`py-2`) yields about 33px, a known gap; touch implementations SHOULD increase vertical padding or add touch-specific sizing.
- **class-name**: Component MUST accept a customization hook for additional styling on the root container and on each subcomponent (on web, a `className` prop; see Platform Notes).


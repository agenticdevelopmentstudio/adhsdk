
- **render-tab-list**: Component MUST render a container for tab buttons with a bottom border line separating tabs from content.
- **render-tabs**: Component MUST render individual clickable tab buttons within the tab list.
- **render-panels**: Component MUST render content panels that display content associated with each tab.
- **default-value**: Component MUST accept a `defaultValue` prop to specify which tab is active on initial render (uncontrolled mode).
- **controlled-value**: Component MUST also support controlled selection via a `value` prop paired with `onValueChange`, both passed through to Base UI's `Tabs.Root`.
- **active-indicator**: Component MUST render a 2px accent-colored border at the bottom of the active tab to indicate selection state.
- **disabled-tabs**: Component MUST respect a `disabled` attribute on individual tabs to block click-activation; the tab remains keyboard-focusable and visually unchanged (no opacity or cursor change — see **Appearance**).
- **click-selection**: Component MUST change the active tab when a user clicks any non-disabled tab button.
- **keyboard-tab-navigation**: Component MUST support Left/Right arrow-key and Home/End navigation among tabs, and roving-tabindex Tab-key entry/exit into the tablist, per Base UI's implementation of the WAI-ARIA APG Tabs pattern.
- **aria-tab-roles**: Component MUST expose `role="tablist"` on the tab container, `role="tab"` with `aria-selected` on each tab, and `role="tabpanel"` on each panel.
- **hover-emphasis**: Component tabs SHOULD change text color on hover to indicate interactivity (from muted to full contrast).
- **focus-visible-state**: Component tabs SHOULD indicate keyboard focus via `focus-visible` styling; the current treatment is a text-color change identical to the hover state, with no separate ring (`outline-none`).
- **class-name**: Component MUST accept a `className` prop for CSS class customization on the root container and each subcomponent.


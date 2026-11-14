
**Decision**: Render tabs as plain `<button type="button">` elements rather than a Base UI `<Tabs>` component or other abstracted tab control.
**Rationale**: These are navigation-style tabs with no associated content panels, so the composite ARIA tabs/tabpanel pattern that a `<Tabs>` primitive implements does not apply; see **no-content-panels**.
**Approved**: pending

**Decision**: Give `endItem` its own `active` property, evaluated independently of the `value` prop.
**Rationale**: Allows an app-level action (e.g., Settings) that is visually styled as a tab but logically independent of the main tab selection.
**Approved**: pending

**Decision**: Keep the component fully controlled — selection state lives in `value`/`onValueChange`, not internal state.
**Rationale**: Lets the parent app orchestrate navigation and keep tab selection synchronized with routing.
**Approved**: pending


**Decision**: Route a click on `endItem` through the same `onValueChange` callback as every other tab, passing its `id`, even though `endItem` never becomes active from `value`.
**Rationale**: The source has one click handler for all tabs, so a consumer tells the end action apart by its `id` and handles it (for example by opening settings) rather than by storing it as the selected value; a separate callback was not added.
**Approved**: pending

**Decision**: Place `endItem` with the physical `ml-auto` utility, which is LTR-only, rather than a logical margin utility.
**Rationale**: This is how the source places it; in a `dir="rtl"` context it stays on the visual right instead of moving to the trailing edge (see the endItem placement edge case).
**Approved**: pending

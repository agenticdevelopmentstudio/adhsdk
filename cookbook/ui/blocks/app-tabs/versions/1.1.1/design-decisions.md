
**Decision**: Render tabs as plain `<button type="button">` elements rather than a Base UI `<Tabs>` component or other abstracted tab control.
**Rationale**: These are navigation-style tabs with no associated content panels, so the composite ARIA tabs/tabpanel pattern that a `<Tabs>` primitive implements does not apply; see **no-content-panels**.
**Approved**: pending

**Decision**: Give `endItem` its own `active` property, evaluated independently of the `value` prop.
**Rationale**: Allows an app-level action (e.g., Settings) that is visually styled as a tab but logically independent of the main tab selection.
**Approved**: pending

**Decision**: Keep the component fully controlled — selection state lives in `value`/`onValueChange`, not internal state.
**Rationale**: Lets the parent app orchestrate navigation and keep tab selection synchronized with routing.
**Approved**: pending


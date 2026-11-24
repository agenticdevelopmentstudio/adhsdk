
- **Decision**: Tabs are wrapped in `role="tablist"` and links in `<nav>`, as two separate ARIA sections rather than one combined list.
  **Rationale**: Tabs are interactive controls that change application state without navigation, while links perform navigation; screen readers must distinguish between these two interaction modes. The visual `gap-4` spacing and flex alignment make both groups appear as one unified row despite their semantic separation.
  **Approved**: pending

- **Decision**: The `title` prop for icon-only tabs is optional rather than required.
  **Rationale**: Icons are common in tab bars, and providing accessible labels for icon-only tabs requires an `aria-label`. Not every tab is icon-only, so the prop is optional, but callers MUST provide it for any tab with an icon label to maintain accessibility compliance.
  **Approved**: pending

- **Decision**: Active state is signaled with `data-active=""` (an empty-string attribute) rather than `data-active="true"`.
  **Rationale**: The presence of the attribute, regardless of value, indicates the active state — matching the CSS attribute-selector convention (`[data-active]`) used throughout the rest of the Tabs component family.
  **Approved**: pending

- **Decision**: The component holds no internal state; it is fully controlled via `value` and `onChange`.
  **Rationale**: Callers MUST manage the `value` state externally and call `onChange` to update it. This lets the parent manage complex logic (e.g., an unsaved Config draft that must survive a tab switch) without the component imposing its own state model.
  **Approved**: pending

- **Decision**: `links` is optional and defaults to an empty array.
  **Rationale**: Route navigation is not needed by every tab bar. Some use cases have tabs only, links only, or both.
  **Approved**: pending



- **Decision**: Represent the "All" (nothing focused) state as `selectedId: null` rather than as a literal item with a special id.
  **Rationale**: This decouples "All" from the item array and simplifies caller logic (e.g., an API filter can use `itemId ?? 'all'`). The tradeoff is that the "All" row is conditionally rendered, and the single-selection group maps `null` to an internal sentinel value (`"__all__"`) that must not collide with a real item id.
  **Approved**: pending

- **Decision**: When an item id collides with the internal `"__all__"` sentinel, log a warning and continue rendering rather than throwing.
  **Rationale**: This is a fail-soft choice: the collision is surfaced to developers via a console warning, but the "All" row and the colliding item remain indistinguishable at runtime — selecting either yields `selectedId: null` — so the warning flags the problem without preventing the ambiguous selection. See **warn-on-sentinel-collision**.
  **Approved**: pending

- **Decision**: Allow the caller to pass extra classes (`className`) that override the trigger's built-in defaults via `cn()`.
  **Rationale**: This provides layout flexibility without prop explosion (e.g., `className="w-auto"` overrides the default `w-full`). The tradeoff is that a destructive override (e.g., removing the focus-visible border) can break accessibility if the caller is not careful.
  **Approved**: pending

- **Decision**: Always render an affordance icon (the default or a custom one); do not offer a prop to hide it.
  **Rationale**: Keeps the API simpler and the dropdown affordance visually consistent — a design allowing the icon to be hidden was rejected for that reason. The icon is excluded from assistive-technology announcements to avoid redundant readback.
  **Approved**: pending

- **Decision**: Make the "New…" entry's label a string prop (`newLabel`), not a `ReactNode` like `icon`.
  **Rationale**: Keeps the API surface smaller and avoids nested-component complexity. A caller needing richer content in the "New…" row would need a separate render-prop API, which was not built.
  **Approved**: pending

- **Decision**: Selecting "New…" invokes the `onNew` callback only; it does not add an item to `items` or change `selectedId`.
  **Rationale**: The caller owns the logic to create a new item and update state, keeping this component focused on selection only — it has no knowledge of routing or deep linking, which remains entirely the caller's responsibility.
  **Approved**: pending


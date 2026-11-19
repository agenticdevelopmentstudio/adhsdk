
- **Role/trait**: Not customized by this component; inherited unmodified
  from the ancestor, whose item rows use a plain text label (with a custom
  accessible-activation override) and whose section headers are marked as
  group items.
- **Label requirements**: Each row's accessible name comes from the
  descriptor's title, which this component copies directly into the
  ancestor's row-item title; the ancestor then uses that same title,
  slugged, as the row's accessibility identifier. This component sets no
  accessibility label or identifier of its own.
- **Announce state changes (e.g., loading, disabled)**: Selection changes
  are posted through the ancestor's own native accessibility notifications
  (inherited, unmodified); this component issues no accessibility
  announcement of its own for a section rebuild, a search filter change, a
  panel's disabled flag flipping, or a descriptor change after the sidebar
  has already been populated — a title or subtitle change rebuilds the
  rows without an announcement, and an icon, disabled-flag, or section
  change leaves the row stale (see Edge Cases, "Descriptor mutated after
  the panel list is set").
- **Minimum tap target**: Not applicable — this is a pointer/keyboard-
  driven list row (no touch input path in this component or its
  ancestor); the 44×44pt minimum is touch guidance, not a pointer-
  interface requirement.


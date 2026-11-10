
- **Decision**: Use a gold bottom-border underline (an accent indicator) rather than a filled pill or box background for the active tab.
  **Rationale**: An underline maintains minimal visual weight and distinguishes the active tab while keeping focus on content; this matches the hub's `/home` tab bar treatment, per the source implementation comment.
  **Approved**: pending

- **Decision**: Use a monospace font (`font-mono`) with increased letter-spacing (`tracking-wide`) for all tab labels.
  **Rationale**: Gives a technical appearance and improves readability of tab labels, especially when labels are short identifiers or status codes.
  **Approved**: pending

- **Decision**: Use flex layout with `gap` utilities (`flex flex-col gap-5` on root, `flex items-end gap-4` on `TabsList`) instead of hard-coded margins.
  **Rationale**: Provides predictable spacing and alignment without per-child margin bookkeeping.
  **Approved**: pending

- **Decision**: Shift the active tab's border with a negative margin (`-mb-px`) so its 2px gold border overlaps and visually replaces the `TabsList`'s 1px bottom border.
  **Rationale**: Creates a seamless transition from list border to tab underline instead of a visible seam between the two borders.
  **Approved**: pending

- **Decision**: Ship `disabled:opacity-50`/`disabled:pointer-events-none` classes that key off the native `:disabled` pseudo-class, even though Base UI's `TabsTab` never sets the native `disabled` attribute (it uses `aria-disabled`/`data-disabled` instead), so the classes never take effect and a disabled tab shows no visual change.
  **Rationale**: Source bug, not a deliberate design choice — the intended dimmed treatment does not render; see `SP/fix/source-bugs.txt`.
  **Approved**: pending

- **Decision**: Build on Base UI's `Tabs` primitive rather than rolling custom tab logic.
  **Rationale**: Base UI provides ARIA compliance (**aria-tab-roles**), keyboard navigation (**keyboard-tab-navigation**), and focus management out of the box; building on a headless primitive is more maintainable than reimplementing tab semantics.
  **Approved**: pending



- **Decision**: Fix the trigger at 24×24px and make it non-resizable.
  **Rationale**: It is a small, compact icon button that fits rail headers and home bars, and stays a fleet-wide sign for "actions on this list" only while every instance looks the same. A developer who needs a different size should compose a custom trigger rather than parameterize this component.
  **Approved**: pending

- **Decision**: Mark the settings icon `aria-hidden`.
  **Rationale**: The `aria-label` already describes the button's action (e.g., "Registry actions"), so the icon itself adds no information and would clutter screen reader output if announced.
  **Approved**: pending

- **Decision**: Exclude menu content (`DropdownMenuContent`, menu items) from the component; render the trigger only.
  **Rationale**: Every list or collection may have different actions, so a one-size-fits-all menu would be unmaintainable. Keeping the component trigger-only keeps it reusable; the host composes it with its own content inside a `DropdownMenu`.
  **Approved**: pending

- **Decision**: Map the `disabled` prop to the trigger's native `disabled` attribute rather than `aria-disabled`.
  **Rationale**: This gives keyboard and assistive technology users the browser's standard disabled-state signal; the tradeoff is that it also removes the trigger from the tab order while disabled (see Accessibility).
  **Approved**: pending


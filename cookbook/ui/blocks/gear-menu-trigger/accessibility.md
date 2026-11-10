
- **Role**: Button (implied by `DropdownMenuTrigger` semantic role).
- **Label**: REQUIRED. The `label` prop provides the accessible name via `aria-label` (requirement **aria-label**). It MUST describe what the menu acts on (e.g., "Registry actions", not just "Menu" or "Actions"); the component does not validate non-emptiness, so the host guarantees a meaningful, non-empty label (requirement **required-label**).
- **Icon announcement**: The icon is `aria-hidden` (requirement **icon-aria-hidden**) to avoid redundant announcements, since the `aria-label` fully describes the button's purpose.
- **Keyboard navigation**: The component is focusable and activatable via keyboard (Enter/Space) because it is a `DropdownMenuTrigger`.
- **Focus indicator**: A 2px gold/40 ring is displayed on keyboard focus (requirement **focus-indicator**), meeting visibility requirements for keyboard navigation.
- **Disabled state announcement**: When `disabled` is `true`, the native `disabled` attribute on the trigger conveys the disabled state to assistive technology; the visual opacity change provides visual feedback. This also removes the trigger from the tab order while disabled — the same as any native disabled button — so a screen-reader user tabbing through the page skips it entirely rather than encountering it as unavailable.


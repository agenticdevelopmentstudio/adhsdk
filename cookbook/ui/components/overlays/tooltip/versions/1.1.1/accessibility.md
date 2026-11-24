
- **Role**: `tooltip` (inherited from Base UI primitive via `role="tooltip"`)
- **Label requirements**: The trigger element SHOULD have an associated label or accessible name that describes its purpose; the tooltip content provides supplementary information only, not the primary label.
- **Keyboard support**: The tooltip MUST display when the trigger element receives focus via keyboard navigation.
- **Announce on open**: The wrapper inherits Base UI Tooltip's `role="tooltip"` and `aria-describedby` wiring. Screen readers announce the tooltip content as the description of the trigger element when the relationship is established via `aria-describedby`.
- **Dismiss, hover, and persist**: See #requirements/dismiss-on-escape, #requirements/remain-open-on-content-hover, and #requirements/dismiss-on-pointer-leave-or-blur (WCAG 1.4.13, Content on Hover or Focus).
- **Minimum touch target**: The trigger element's touch target size is the consuming application's responsibility (recommended minimum 44×44pt per platform guidelines); the tooltip content itself is non-interactive and has no target of its own.



These requirements describe the full-featured variant only, which wraps Base UI's Popover. The lightweight variant renders a plain `<div>` with mouse handlers and has no ARIA role, no focus management, and no keyboard equivalent to its hover trigger — it is a pointer-only affordance.

- **dialog-role** (full-featured): The popover content MUST be assigned the `dialog` role via Base UI's `Popover.Popup`.
- **return-focus-on-close** (full-featured): The popover is non-modal by default (Base UI `Popover.Root`'s `modal` prop, not set by this wrapper, defaults to `false`), so opening it does not trap focus inside the panel. When the popover closes via Escape, or via an outside interaction that lands on a non-focusable area, focus MUST return to the trigger element (Base UI's default `finalFocus` behavior). When the popover instead closes because focus itself left the panel (Tab past the last focusable element, Base UI's `focus-out` dismissal), Base UI suppresses the return-focus behavior and forwards focus to the next tabbable element after the trigger instead — the closing Tab keypress is left to complete its forward navigation rather than being undone (see popover-022).
- **escape-closes** (full-featured): The Escape key MUST close the popover (Base UI Popover's native keyboard handling).
- **aria-expanded** (full-featured): The trigger element MUST have `aria-expanded="true"` when the popover is open and `aria-expanded="false"` when closed (Base UI `Popover.Trigger` handles this automatically).
- **label-association** (full-featured): The popover SHOULD be associated with a descriptive label via `aria-labelledby` or `aria-label` on `Popover.Popup` for screen reader users.
- **live-region-updates** (full-featured, lightweight): Dynamic content changes inside the panel SHOULD use `aria-live="polite"` or `aria-live="assertive"` as appropriate to announce updates to assistive technology users.


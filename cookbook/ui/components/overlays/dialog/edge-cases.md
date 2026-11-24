
- **Backdrop dismissal**: see [backdrop-dismissal-disabled](#requirements/backdrop-dismissal-disabled) for the default and the opt-in.
- **Content width**: Dialog caps at `max-w-md` (448px); composing dialogs widen it via className override (e.g., `sm:max-w-2xl`).
- **Close button hide**: `showClose={false}` hides the affordance for dialogs whose footer buttons are the only dismissal path (e.g., a busy/loading state that also overrides [escape-closes](#requirements/escape-closes) (per [escape-overridable](#requirements/escape-overridable)) so Escape is blocked while busy).
- **Responsive behavior**: `w-[calc(100%-2rem)]` preserves 16px side margins on small screens; margins prevent edge-touching on mobile.
- **Escape override, uncontrolled**: A composing component passes its own `onOpenChange` (forwarded via `{...props}` on the `Dialog` root) and calls `eventDetails.cancel()` on the event-details argument when the reason is Escape. Base UI ignores a plain `event.preventDefault()` here.
- **Escape override, controlled**: With a controlled `open`, the composing component simply returns from `onOpenChange` without setting `open` to `false`, e.g. a search input within the dialog that wants to capture Escape for its own purposes.
- **Missing title**: A `<DialogContent>` rendered without `<DialogTitle>` has no `aria-labelledby` and is announced to assistive technology with no accessible name; see [dialog-labelling](#requirements/dialog-labelling); hide the title visually with CSS if a visible one isn't wanted.



- **Backdrop dismissal is off by default** (see **backdrop-dismissal-disabled**) for modals/alerts — users opt back in with `disablePointerDismissal={false}`.
- **Content width**: Dialog caps at `max-w-md` (448px); composing dialogs widen it via className override (e.g., `sm:max-w-2xl`).
- **Close button hide**: `showClose={false}` hides the affordance for dialogs whose footer buttons are the only dismissal path (e.g., a busy/loading state that also overrides **escape-closes** so Escape is blocked while busy).
- **Responsive behavior**: `w-[calc(100%-2rem)]` preserves 16px side margins on small screens; margins prevent edge-touching on mobile.
- **Escape override**: A composing component overrides **escape-closes** by passing its own `onOpenChange` (forwarded via `{...props}` on the `Dialog` root) and checking the dismissal reason before calling `eventDetails.cancel()` on the event-details argument — Base UI ignores a plain `event.preventDefault()` here — or, with a controlled `open`, by simply returning without flipping it to `false` — e.g., a search input within the dialog that wants to capture Escape for its own purposes.
- **Missing title**: A `<DialogContent>` rendered without `<DialogTitle>` has no `aria-labelledby` and is announced to assistive technology with no accessible name; composing components MUST always render `DialogTitle` (see **dialog-labelling**), hiding it visually with CSS if a visible title isn't wanted.


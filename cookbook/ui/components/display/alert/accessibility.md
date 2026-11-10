
- Role/trait: `role="alert"` on the root element, for every variant.
  `AlertTitle` and `AlertDescription` carry no ARIA role of their own — they
  are plain `<div>`s identified only by their `data-slot` attribute.
- Label requirements: Not applicable: AlertTitle and AlertDescription are unstyled, positioned grid cells; callers provide content and manage any labeling strategy independently.
- Announce state changes: `role="alert"` makes the root an implicit ARIA
  live region (assertive, atomic, per the ARIA specification), so
  assistive technology announces the element's text content when it is
  inserted into the DOM or when that content changes. `alert.tsx` adds no
  further state-change handling beyond this native role behavior (no
  `aria-live` override, no imperative announce call).
- Minimum tap target: Not applicable: Alert is a non-interactive presentational container with no interactive controls or tap targets of its own.


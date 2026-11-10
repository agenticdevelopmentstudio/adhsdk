
- **render-button**: Component MUST render as a `<button>` element with `type="button"`.
- **read-appearance-mode**: Component MUST read the appearance mode from `document.documentElement.dataset.appearanceMode` and treat any unrecognized value as 'auto'.
- **read-resolved-appearance**: Component MUST read the resolved appearance from whether the 'dark' class exists on `document.documentElement`, with 'dark' resolving to 'dark' and absence resolving to 'light'.
- **display-icon-based-on-resolved**: Component MUST display a moon icon when resolved appearance is 'dark' and a sun icon when resolved appearance is 'light'.
- **display-badge-in-auto-mode**: Component MUST display an auto badge element (span with nested SVG) when appearance mode is 'auto'.
- **dispatch-cycle-event-on-click**: Component MUST dispatch a custom event named 'awt:appearance-cycle' on `window` when the button is clicked, with no `detail` payload. The component does not change the mode itself — see **External appearance controller** in Design Decisions.
- **listen-for-appearance-changed-event**: Component MUST listen for the 'awt:appearance-changed' custom event on `window` (no `detail` payload is read) and re-read the appearance mode and resolved appearance from `document.documentElement` when the event is received.
- **set-aria-label**: Component MUST set `aria-label` to one of three templates, chosen by mode and resolved appearance: when mode is 'auto', `"Appearance: Auto (currently {resolved}). Click to switch to dark."`; when mode is 'dark', `"Dark mode — click for light"`; when mode is 'light', `"Light mode — click for auto"`.
- **set-title-attribute**: Component MUST set the `title` attribute to the same value as `aria-label`.
- **accept-classname-prop**: Component MUST accept an optional `className` prop and merge it with the component's base class name 'awt-appearance-mode-toggle'.
- **render-hydration-safe**: Component MUST render without throwing when `document` is unavailable (server-side rendering), defaulting to 'auto' mode and 'light' resolved appearance in that case. The read happens via a `useState` lazy initializer that runs synchronously during render — including the client's first (hydrating) render — so it is not deferred until after mount; the client's hydrating render re-reads the live `document.documentElement` immediately, which can differ from the server's deterministic auto/light output (see Design Decisions: Hydration safety).


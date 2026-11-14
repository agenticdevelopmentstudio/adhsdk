
- **Empty or zero-width labels**: a button with no content collapses to its padding,
  which is its natural width; the cap is simply small and the other button takes the
  slack. There is no "unmeasured" state to guard against, because nothing is measured.
- **Confirm-only**: with no `cancelLabel`, the lone confirm button sits at its natural
  width on the right. Forced-equal still does not stretch it.
- **One button outgrows its half, the other does not**: the small one settles at its
  natural width and the large one takes the remainder, instead of both snapping to an
  even split and truncating the large one. This is the one behavioural difference from
  the previous `2 × Wmax` threshold, and it is strictly the better answer.
- **Boundary width**: there is no threshold to sit exactly on. The row passes
  continuously between the two shapes as the container narrows, so no flicker band
  exists.
- **Busy**: the spinner path renders no buttons at all, so the layout question does
  not arise.
- **Label change**: a longer label changes the button's natural width, and the layout
  engine re-resolves during the same layout pass that reflows the text — there is no
  second pass to observe.
- **Confirm disabled while button has focus**: if the confirm button is focused and
  `confirmDisabled` flips to true, the button is disabled but focus is not moved; the
  next click attempt will fail silently (the button does not fire). The host is
  responsible for moving focus if needed (e.g. to the cancel button). This is a
  deliberate choice, not an oversight — see Design Decisions.
- **Initial focus fallback**: when the preferred button named by `initialFocus` is
  disabled or absent, focus moves to the other button instead of nowhere (see
  **focus-fallback-to-other-button**). When both are missing or disabled, the component
  leaves focus wherever the host dialog already placed it rather than forcing it anywhere;
  it relies on the host dialog's own focus management (for example base-ui's Popup) to keep
  a trap in place.


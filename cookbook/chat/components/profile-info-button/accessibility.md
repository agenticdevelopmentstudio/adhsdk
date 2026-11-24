
- **Role/trait**: Link. The root is a native anchor with an `href`, so it is focusable and activated by Enter without extra code.
- **Label requirements**: `label` is required and becomes both `aria-label` and `title`; the visible "i" is hidden from assistive technology.
- **Keyboard**: Reachable with Tab in document order and activated with Enter, as for any anchor. Focus is shown by the border and glow described under States.
- **Announce state changes**: Not applicable: the component has no changing state. Activation opens a new tab; the source gives no cue that the link opens a new tab beyond the `label` the host supplies.
- **Minimum tap target**: see the open question on `target-size` under Appearance.


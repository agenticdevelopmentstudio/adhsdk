
- Container: `role="group"` with `aria-label` from the `ariaLabel` prop.
- Inline input: `aria-label={`Add to ${ariaLabel}`}` to label the entry field; the same label is applied to the separate mode's `Input`.
- Invalid chips: carry `aria-invalid="true"`.
- Removable chips: each remove control is a real `<button>` with accessible name `Remove ${value}` — for example, a chip holding `ada@x.io` gets a remove button labeled exactly "Remove ada@x.io".
- Tab order: chips render before the input in DOM order, so keyboard focus visits each chip's remove button in `value` array order, then the inline input (fused mode) or the separate `Input` below the recipients box (separate mode). No explicit `tabindex` is set; order follows render order.
- No live-region announcement: the component does not announce chip addition, rejection, or removal to assistive technology. A newly added invalid chip is discoverable via its own `aria-invalid` attribute once focus or a screen reader's browse cursor reaches it, but there is no `aria-live` region confirming the add, reject, or remove action as it happens.
- Differentiate Without Color: see Accessibility Options.
- Input type hints: `inputMode` reflects the `kind` prop to guide mobile keyboards, in both fused and separate modes.


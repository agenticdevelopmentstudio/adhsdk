
- **Role**: The component renders a native `<hr>`, which the browser exposes as a separator; the source adds no ARIA attribute.
- **Label requirements**: Not applicable: the rule carries no text and is not interactive, so it needs no label.
- **Announce state changes**: Not applicable: the animation changes only opacity and no state is announced.
- **Minimum tap target**: Not applicable: the rule is not interactive, so no touch or click target is involved.
- **reduced-motion-support**: The rule MUST stop animating and sit at full opacity when the reader has asked for reduced motion. The stylesheet comment gives the reason: "a reader who has asked for less motion has not asked for a fainter page".
- **separator-exposure**: The component renders a native `<hr>` and adds no `role`, `aria-hidden` or other ARIA attribute, so a browser exposes it as a separator and a screen reader may announce it beneath the hero name. The source does not mark the hairline as presentation.
- **rule-contrast**: NEEDS REVIEW: Not implemented in source. The source cannot say whether the 1px accent hairline, faded to transparent at both ends and at 0.35 opacity at its floor, meets any contrast threshold against the host's background; a contrast measurement against the host theme's accent and surface colors would settle it.


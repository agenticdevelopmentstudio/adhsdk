
**Decision**: Use `inline-flex` rather than `flex` for the outer container.
**Rationale**: Lets the component sit within text and form flows without breaking layout; matches the source constraint and Web semantic expectations.
**Approved**: pending

**Decision**: Include a transparent 1px border on the track.
**Rationale**: Reserves layout space so applying the focus ring doesn't shift surrounding content.
**Approved**: pending

**Decision**: The thumb travels 16px to the right when checked.
**Rationale**: The source's `translate-x-4` Tailwind utility is a 16px transform measured from the thumb's starting position, and the starting padding inset does not reduce it. The 36px track leaves only 14px of free travel once the 1px border, 4px of horizontal padding (2px each side), and the 16px thumb are subtracted (36 − 2 − 4 − 16 = 14), so the thumb overshoots the 2px right padding by 2px. A port can match this, or use a 14px travel to end flush with the padding.
**Approved**: pending

**Decision**: Animate both the track color and the thumb position rather than switching instantly.
**Rationale**: Matches modern UI expectations for visual feedback and improves perceived responsiveness.
**Approved**: pending

**Decision**: Rely on the design system's accent, input-surface and foreground color roles rather than hardcoded colors.
**Rationale**: Keeps the component's colors consistent with the rest of the design system; no fallback is provided: if a token is undefined, the component will fail to display correctly, which is a consumer responsibility.
**Approved**: pending

**Decision**: Support both controlled (`checked` / `onCheckedChange`) and uncontrolled (`defaultChecked`) usage.
**Rationale**: Lets consumers choose based on their own state-management needs; the source does not force one pattern.
**Approved**: pending


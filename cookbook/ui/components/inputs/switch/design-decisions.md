
**Decision**: Use `inline-flex` rather than `flex` for the outer container.
**Rationale**: Lets the component sit within text and form flows without breaking layout; matches the source constraint and Web semantic expectations.
**Approved**: pending

**Decision**: Include a transparent 1px border on the track.
**Rationale**: Reserves layout space so applying the focus ring doesn't shift surrounding content.
**Approved**: pending

**Decision**: The thumb travels 14px to the right when checked.
**Rationale**: The 36px track leaves 14px of travel once the 1px border, 4px of horizontal padding (2px each side), and the 16px thumb are subtracted (36 − 2 − 4 − 16 = 14). The source's `translate-x-4` Tailwind utility requests 16px (Tailwind's default spacing scale), but the thumb starts already inset by the track's padding, so its visual travel lands exactly at this 14px right-aligned position.
**Approved**: pending

**Decision**: Animate both the track color and the thumb position rather than switching instantly.
**Rationale**: Matches modern UI expectations for visual feedback and improves perceived responsiveness.
**Approved**: pending

**Decision**: Rely on the design system's color tokens (`apt-gold`, `apt-input`, `apt-text`) rather than hardcoded colors.
**Rationale**: Keeps the component's colors consistent with the rest of the design system; if a token is undefined, the component will fail to display correctly, which is a consumer responsibility.
**Approved**: pending

**Decision**: Support both controlled (`checked` / `onCheckedChange`) and uncontrolled (`defaultChecked`) usage.
**Rationale**: Lets consumers choose based on their own state-management needs; the source does not force one pattern.
**Approved**: pending


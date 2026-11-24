
**Decision**: The look is split into a stylesheet class and two custom properties (`--lp-pulse-rule-period` and `--lp-pulse-rule-floor`) rather than variant props.
**Rationale**: The `blocks.css` comment says "Two custom properties rather than two variants": a host that wants a slower or shallower rule sets a property on the element, and the component needs no prop for it.
**Approved**: pending

**Decision**: `className` is appended to `lp-pulse-rule` and never replaces it.
**Rationale**: The source comment states the split: placement (width, margins) is the caller's, and how the rule looks is this component's.
**Approved**: pending

**Decision**: The gradient fades to transparent at both ends instead of starting solid.
**Rationale**: The `blocks.css` comment explains that a rule that starts solid and trails off has a left edge, and this one is drawn under centred type.
**Approved**: pending

**Decision**: The breathing animates opacity and not a colour ramp.
**Rationale**: The `blocks.css` comment says opacity is compositor-only, so the rule can breathe for as long as the page is open without asking for a paint.
**Approved**: pending

**Decision**: Under reduced motion, the rule rests at full opacity (1) and not at the floor.
**Rationale**: The `blocks.css` comment says "a reader who has asked for less motion has not asked for a fainter page".
**Approved**: pending

**Decision**: The component is a server component with no client code.
**Rationale**: The source comment says the breathing is a CSS animation, so nothing needs to run in the browser, and the test asserts that the client barrel re-exports nothing of it.
**Approved**: pending


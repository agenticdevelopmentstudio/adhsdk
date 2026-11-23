
**Decision**: the agent list reuses the element picker whole, with the list
as a parameter.
**Rationale**: One picker, popover and dialog for both lists keeps their
behavior identical and fixes once (`dry`); only the entry point, list and
wording differ.
**Approved**: pending

**Decision**: a preview pick saves the selector the gatekeeper recorded for
the node's ref, not one computed in the preview.
**Rationale**: The preview's markup is the gatekeeper's own construction,
not the page's; a selector computed against it would not match the live
DOM the gatekeeper walks. The ref ties the preview node to the live
element the walker saw.
**Approved**: pending

**Decision**: the agent popover has no site switch.
**Rationale**: Turning the whole agent list off for a site would be a
one-click leak; entries are disabled one at a time, deliberately.
**Approved**: pending

**Decision**: the picker world runs in the preview while page JavaScript
stays off.
**Rationale**: The preview must show only what the gatekeeper put in, so
page scripts stay off; the picker lives in its own world and needs none of
them. WebKit documents `allowsContentJavaScript` as turning off the
page's own scripts only, leaving scripts the app evaluates in a content
world running, so the implementation installs the picker with
`evaluateJavaScript(_:in:in:)` and leaves the preference off. Finding (to
be recorded from the verification run): whether the picker does run in the
preview with page JavaScript off. If it does not, the preview enables only
the picker world, never page scripts.
**Approved**: pending


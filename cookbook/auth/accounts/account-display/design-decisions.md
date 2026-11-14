
**Decision**: While busy, the display keeps showing the user shown before the work began (supplied by the caller as `lastUser`) instead of switching to the signed-out controls.
**Rationale**: The source documents this: signing out keeps showing who is signing out rather than flashing the signed-out controls. The display stays stateless, so the caller carries the previous `shownUser` forward.
**Approved**: pending

**Decision**: A busy account with no remembered user renders as signed out (Login, and Signup when a URL exists), with every control disabled.
**Rationale**: Signing in through a browser sheet starts from the signed-out state, so the signed-out controls stay in place, disabled, rather than vanishing during the sign-in.
**Approved**: pending

**Decision**: `controlsEnabled` depends only on busy, not on whether a button is visible.
**Rationale**: The source's doc comment states it as "False while busy: every button is disabled", a single rule that views apply to whichever buttons they show; during restoring no button shows, so the value is not consulted.
**Approved**: pending

**Decision**: `restoringText` is a hardcoded English constant on the type and the account `message` is passed through verbatim.
**Rationale**: The source places the one status line the display itself owns in one constant so both platforms show the same text, and leaves the wording of errors to the account that produces them.
**Approved**: pending


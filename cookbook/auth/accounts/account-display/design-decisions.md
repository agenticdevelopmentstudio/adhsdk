All four decisions are `Approved: pending`: the recipe is in review and none has been settled by the owner yet.

**Decision**: While busy, the display keeps showing the user shown before the work began (supplied by the caller as `lastUser`) instead of switching to the signed-out controls.
**Rationale**: Without it, a sign-out in progress would flash the signed-out controls instead of showing who is signing out (the doc comment on `AccountDisplay.shownUser`). The display stays stateless, so the caller carries the previous `shownUser` forward.
**Approved**: pending

**Decision**: A busy account with no remembered user renders as signed out (Login, and Signup when a URL exists), with every control disabled.
**Rationale**: Signing in through a browser sheet starts from the signed-out state, so the signed-out controls stay in place, disabled, rather than vanishing during the sign-in.
**Approved**: pending

**Decision**: `controlsEnabled` depends only on busy, not on whether a button is visible.
**Rationale**: One rule, "False while busy: every button is disabled" (the doc comment on `AccountDisplay.controlsEnabled`), applies to whichever buttons a view shows. During restoring no button shows, so the value is unspecified there and no consumer depends on it.
**Approved**: pending

**Decision**: `restoringText` is a hardcoded English constant on the type and the account `message` is passed through verbatim.
**Rationale**: One constant on the type (`AccountDisplay.restoringText`) makes both platforms show the same text, and the account that produces an error owns its wording. The hardcoded literal is known internationalization debt, which is why `no-hardcoded-strings` is `failed`. It should be paid off by looking the text up under a key such as `account.status.restoring` with the English default `Checking sign-in…`, when the SDK gains a localization layer.
**Approved**: pending



**Decision**: Every view action goes through one private call path that runs the action, then always reloads provider and accounts.
**Rationale**: The reload makes the model show the service's state, which also repairs optimistic changes after a failure.
**Approved**: pending

**Decision**: Settings updates apply locally at once, then coalesce per account to the latest value while a send is in flight.
**Rationale**: A stepper or toggle can change faster than the service answers, and each change must not restart a sync. A failure drops all pending values and reloads, so the user may lose several intermediate choices at once.
**Approved**: pending

**Decision**: A reload that lands mid-send re-applies the newest chosen settings over the service's list.
**Rationale**: A change made while reloading has not reached the service yet, so the model keeps showing it and avoids a visible snap back to the old value.
**Approved**: pending

**Decision**: Sign-ins are ordered by a shared tracker rather than by each model alone.
**Rationale**: The browser return says only that a sign-in finished, not where it began, and the same settings may show on several surfaces. A model that never signed in reports false.
**Approved**: pending

**Decision**: Account errors alert once per account and message, and the row carries only the "Error" badge; "Show Error" reopens the alert on request.
**Rationale**: Alerting again about the same failure on every reload would nag the user, so the model remembers what it alerted and forgets an account once it recovers, so a later identical failure alerts. Only one alert shows at a time.
**Approved**: pending

**Decision**: The client secret is shown as a fixed ten-bullet mask plus the last five characters of the secret that the mail integration service sends in the provider status (see the [mail integration service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a), which owns the five-character limit), or "Stored (hidden)" when no suffix exists.
**Rationale**: A fixed mask length does not reveal the secret's length, and the service sends only those characters.
**Approved**: pending

**Decision**: `cancelSignIn` makes its own call without the shared call path, so it neither reloads nor changes `busy`.
**Rationale**: The pending sign-in call is the one that fails with "Sign-in was cancelled" and reloads, so a second reload would duplicate that work. This is a quirk: when the pending sign-in then fails, its own call sets `errorMessage` to that failure, so a cancel failure message can be replaced.
**Approved**: pending

**Decision**: Display strings are English literals inside the model, with the clock and locale injectable for tests.
**Rationale**: Keeping the text beside the state lets the model's tests cover it. This is deliberate technical debt for localization, tracked on `string-externalization` in Localization. It is retired when the first non-English locale ships for the Integrations settings screen, or when the product decides how that screen is localized, whichever comes first; the owner is the Integrations settings screen's maintainer.
**Approved**: pending


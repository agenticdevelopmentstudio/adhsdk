
**Decision**: Every view action goes through one private call path that runs the action, then always reloads provider and accounts.
**Rationale**: The source comment says the reload happens "so the model shows the server's state", which also repairs optimistic changes after a failure.
**Approved**: pending

**Decision**: Settings updates apply locally at once, then coalesce per account to the latest value while a send is in flight.
**Rationale**: The source comment says a stepper or toggle can change faster than the service answers, and "each change does not restart a sync". A failure drops all pending values and reloads, so the user may lose several intermediate choices at once.
**Approved**: pending

**Decision**: A reload that lands mid-send re-applies the newest chosen settings over the service's list.
**Rationale**: The source comment says a change made while reloading "has not reached the service yet; keep showing it", avoiding a visible snap back to the old value.
**Approved**: pending

**Decision**: Sign-ins are ordered by a shared tracker rather than by each model alone.
**Rationale**: The browser return says only that a sign-in finished, not where it began, and the same settings may show on several surfaces. A model that never signed in reports false.
**Approved**: pending

**Decision**: Account errors alert once per account and message, and the row carries only the "Error" badge; "Show Error" reopens the alert on request.
**Rationale**: The source comment says the model does not alert again about the same failure on reload, and forgets an account once it recovers so a later identical failure alerts. Only one alert shows at a time.
**Approved**: pending

**Decision**: The client secret is shown as a fixed ten-bullet mask plus the last five characters the daemon sends, or "Stored (hidden)" when no suffix exists.
**Rationale**: The source comment says the mask length is fixed so it does not reveal the secret's length, and the daemon sends only those characters.
**Approved**: pending

**Decision**: `cancelSignIn` makes its own call without the shared call path, so it neither reloads nor changes `busy`.
**Rationale**: The pending sign-in call is the one that fails with "Sign-in was cancelled" and reloads, so a second reload would duplicate that work. This is a quirk: the pending sign-in's own call clears and may overwrite `errorMessage`, so a cancel failure message can be replaced.
**Approved**: pending

**Decision**: Display strings are English literals inside the model, with the clock and locale injectable for tests.
**Rationale**: The source keeps the text beside the state so it is tested with the model. This is technical debt for localization, tracked on the open question on `string-externalization`.
**Approved**: pending


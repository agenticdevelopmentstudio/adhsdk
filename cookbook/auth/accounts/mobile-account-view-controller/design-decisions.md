
**Decision**: The screen keeps no account state of its own and derives all visibility from `AccountDisplay`.
**Rationale**: The macOS and iOS panels must follow the same rules; the source states "nothing here keeps a copy of the account's state". The only carried value is the last shown user, kept so a busy sign-out still shows who is signing out.
**Approved**: pending

**Decision**: The screen sets the account's single change slot in view load and replaces any earlier observer.
**Rationale**: The `Account` contract says the accounts UI that shows the account is its one observer. Rendering before load only updates rows because no callback is set until then.
**Approved**: pending

**Decision**: Restore is called after the first render in view load.
**Rationale**: The `Account` contract says the accounts UI calls restore when it first shows the account, so an app pays for the stored-login check only when someone looks.
**Approved**: pending

**Decision**: Disabled actions stay visible in the tertiary label color and ignore touches, instead of being hidden.
**Rationale**: The display's `controlsEnabled` is false while busy; hiding the rows would make the screen jump when sign-in or sign-out starts.
**Approved**: pending

**Decision**: An account message replaces the summary footer in every state, including while signed in.
**Rationale**: The source comment states the message (an error) replaces the summary whenever there is one, so an error is never hidden behind explanatory text.
**Approved**: pending

**Decision**: Row strings are literals, not localized resources, and the status literal "Working…" lives in the screen while "Checking sign-in…" lives in `AccountDisplay`.
**Rationale**: Technical debt noted for fidelity: the source has no localization layer, so implementers on other platforms must add their own.
**Approved**: pending

**Decision**: The open-URL closure SHOULD be injectable.
**Rationale**: It lets tests record the signup URL without launching the system; a host may deviate by hard-wiring the system opener, at the cost of testability.
**Approved**: pending


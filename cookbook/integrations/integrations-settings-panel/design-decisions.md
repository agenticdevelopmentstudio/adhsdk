
**Decision**: Unknown provider state counts as configured when removing, so only a loaded `configured` of false skips the remove call.
**Rationale**: The source comment says removing an integration that is not there is harmless, while skipping one that is leaks its secrets.
**Approved**: pending

**Decision**: Picking Gmail from `+` is held only in memory and nothing is sent to the service until the OAuth client is imported.
**Rationale**: The source comment says Gmail "stays listed, in memory, until it is configured"; this lets the user reach the OAuth client form without creating service state.
**Approved**: pending

**Decision**: The listing rebuild runs one main-queue turn after the provider publishes.
**Rationale**: The source comment says `$provider` publishes before the new value lands, so reading it immediately would see the old value.
**Approved**: pending

**Decision**: The panel exposes `startedLatestSignIn` and `reloadAfterSignIn()` instead of reloading on appearance.
**Rationale**: The source comment says a panel brought back to the front gets no appearance callback, so the landing asks for the reload itself.
**Approved**: pending

**Decision**: The panel lists a single integration through a general sidebar, add menu and footer.
**Rationale**: The doc comment says "today only Gmail"; the sidebar, add menu and removal flow are built so further integrations can be added, but the code has one hardcoded branch for Gmail rather than a registry.
**Approved**: pending

**Decision**: Strings are literals and the panel writes no log entries.
**Rationale**: The source has no localization or logging calls; this is recorded as technical debt for the localization check and does not change behavior.
**Approved**: pending

**Decision**: The panel has no unit test of its own.
**Rationale**: Only `GmailSettingsModelTests` exist for the code it drives, and they cover the model, not the listing, the add menu or the removal flow; this affects the test coverage compliance result.
**Approved**: pending



**Decision**: Use one enum for every integration failure (settings, sign-in, token refresh, Keychain, lookup, Gmail) instead of one error type per layer.
**Rationale**: The doc comment says every case reads as a sentence a person can act on, so any layer's failure can reach the UI and the stored `lastError` through one description path. `MailIntegrationService.handle` relies on this when it turns any thrown error into `.failure(localizedDescription)`.
**Approved**: pending

**Decision**: Keep `revoked` separate from `tokenRefresh` and `signInFailed`.
**Rationale**: `MailIntegrationService` compares against `.revoked` to mark a connection `revoked` (the user must sign in again) and marks every other failure `error`. Folding it into a string case would break that comparison.
**Approved**: pending

**Decision**: Carry Gmail failures as `gmail(status:message:)`, with status 0 for a failure before any response.
**Rationale**: Callers pattern-match on status 400 and 404 to treat a missing item as gone, so the number has to stay machine-readable instead of being folded into the message.
**Approved**: pending

**Decision**: Hardcode the English descriptions in the enum.
**Rationale**: The source has no string table. Whether to localize is an owner decision, so this recipe records the current behavior as the contract.
**Approved**: pending

**Decision**: Keep `unknownLabel` although no other integrations file throws it.
**Rationale**: It is part of the declared public case set and has a defined description. Removing it would change the public surface; whether to remove it is for the owner.
**Approved**: pending


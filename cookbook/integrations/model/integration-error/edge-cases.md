
- **empty-payload**: A payload string MAY be empty, and the description then ends with its prefix and no text (`Sign-in failed: `); the type does not validate payloads.
- **negative-or-zero-status**: `gmail` accepts any `Int` status, including 0 (used for an unbuildable URL or a wrong-size `batchModify` id list) and negative values; the type applies no range check.
- **special-characters**: A payload containing quotes, newlines or non-ASCII text appears in the description unchanged. See #requirements/desc-verbatim-payload.
- **unknown-label-unused**: `unknownLabel` exists and has a description, but nothing in the integrations sources throws it. See #requirements/keep-unknown-label.
- **equality-of-payloads**: Two `gmail` values with the same status and different messages are not equal. See #requirements/conforms-equatable.
- **concurrent-access**: Not applicable: the enum is an immutable `Sendable` value with no shared mutable state, so it can be passed between tasks freely.
- **cancellation**: Task cancellation is not itself an `IntegrationError`; only the sign-in paths convert it to `signInCancelled`, and `MailIntegrationService` ignores `CancellationError` when recording connection status.
- **offline-or-timeout**: Not applicable: the type performs no I/O. It has no timeout or connectivity case; a sign-in timeout is reported as `signInFailed("Sign-in timed out")`.
- **boundary-values**: Not applicable beyond the status integer above: the type constrains no other numeric input. Range checks (1–3650, 1–1440) live in `MailSyncSettings`.

